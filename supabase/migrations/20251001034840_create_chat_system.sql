/*
  # Chat System Schema

  ## Description
  Creates tables for real-time messaging between students and tutors.

  ## Tables Created
  
  ### 1. chat_messages
    - Stores all messages between matched users
    - Supports read receipts
    - Enables real-time subscriptions
  
  ### 2. blocked_users
    - Allows users to block other users
    - Prevents communication between blocked users
  
  ### 3. reports
    - Handles user reports for inappropriate behavior
    - Tracks report status and admin actions
  
  ## Security
    - RLS enabled on all tables
    - Users can only access messages from their matches
    - Blocked users cannot communicate
    - Privacy-focused access control
*/

-- Chat messages table
CREATE TABLE IF NOT EXISTS chat_messages (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  sender_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  message_text text NOT NULL CHECK (length(message_text) > 0),
  is_read boolean DEFAULT false,
  read_at timestamptz,
  created_at timestamptz DEFAULT now()
);

-- Blocked users table
CREATE TABLE IF NOT EXISTS blocked_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  blocked_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason text,
  created_at timestamptz DEFAULT now(),
  UNIQUE(blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)
);

-- Reports table
CREATE TABLE IF NOT EXISTS reports (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reported_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  report_type text NOT NULL CHECK (report_type IN (
    'inappropriate_content',
    'harassment',
    'spam',
    'fake_profile',
    'underage',
    'other'
  )),
  description text NOT NULL,
  related_message_id uuid REFERENCES chat_messages(id),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'resolved', 'dismissed')),
  admin_notes text,
  resolved_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  resolved_at timestamptz
);

-- Enable Row Level Security
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

-- RLS Policies for chat_messages
CREATE POLICY "Users can view messages they sent"
  ON chat_messages FOR SELECT
  TO authenticated
  USING (auth.uid() = sender_id);

CREATE POLICY "Users can view messages they received"
  ON chat_messages FOR SELECT
  TO authenticated
  USING (auth.uid() = receiver_id);

CREATE POLICY "Users can send messages"
  ON chat_messages FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() = sender_id
    AND NOT EXISTS (
      SELECT 1 FROM blocked_users
      WHERE (blocker_id = receiver_id AND blocked_id = sender_id)
         OR (blocker_id = sender_id AND blocked_id = receiver_id)
    )
  );

CREATE POLICY "Users can mark received messages as read"
  ON chat_messages FOR UPDATE
  TO authenticated
  USING (auth.uid() = receiver_id)
  WITH CHECK (auth.uid() = receiver_id);

-- RLS Policies for blocked_users
CREATE POLICY "Users can view their blocks"
  ON blocked_users FOR SELECT
  TO authenticated
  USING (auth.uid() = blocker_id);

CREATE POLICY "Users can block others"
  ON blocked_users FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = blocker_id);

CREATE POLICY "Users can unblock others"
  ON blocked_users FOR DELETE
  TO authenticated
  USING (auth.uid() = blocker_id);

-- RLS Policies for reports
CREATE POLICY "Users can view own reports"
  ON reports FOR SELECT
  TO authenticated
  USING (auth.uid() = reporter_id);

CREATE POLICY "Users can create reports"
  ON reports FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = reporter_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_chat_messages_match ON chat_messages(match_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_receiver ON chat_messages(receiver_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_unread ON chat_messages(receiver_id, is_read) WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON blocked_users(blocked_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported ON reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);

-- Trigger for reports updated_at
CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to get unread message count for a user
CREATE OR REPLACE FUNCTION get_unread_message_count(p_user_id uuid)
RETURNS integer AS $$
DECLARE
  v_count integer;
BEGIN
  SELECT COUNT(*)::integer INTO v_count
  FROM chat_messages
  WHERE receiver_id = p_user_id
    AND is_read = false;
  
  RETURN COALESCE(v_count, 0);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to mark messages as read
CREATE OR REPLACE FUNCTION mark_messages_as_read(
  p_user_id uuid,
  p_match_id uuid
)
RETURNS integer AS $$
DECLARE
  v_updated_count integer;
BEGIN
  UPDATE chat_messages
  SET is_read = true,
      read_at = now()
  WHERE receiver_id = p_user_id
    AND match_id = p_match_id
    AND is_read = false;
  
  GET DIAGNOSTICS v_updated_count = ROW_COUNT;
  
  RETURN v_updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

/*
  # Matching and Lessons Schema

  ## Description
  Creates tables for matching requests, lessons, and relationships between students and tutors.

  ## Tables Created
  
  ### 1. matches
    - Stores matching requests between students and tutors
    - Tracks approval status and matching fee payment
  
  ### 2. lessons
    - Stores lesson booking information
    - Handles escrow system for payments
    - Tracks lesson status from application to completion
  
  ### 3. favorites
    - Allows students to save favorite tutors
  
  ## Security
    - RLS enabled on all tables
    - Users can only access their own match/lesson data
    - Proper access control for students and tutors
*/

-- Matches table
CREATE TABLE IF NOT EXISTS matches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tutor_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  request_message text NOT NULL CHECK (length(request_message) >= 20),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
  matching_fee_paid boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  responded_at timestamptz,
  UNIQUE(student_id, tutor_id)
);

-- Lessons table
CREATE TABLE IF NOT EXISTS lessons (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id uuid NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
  student_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tutor_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  subject text NOT NULL,
  scheduled_date date NOT NULL,
  scheduled_time time NOT NULL,
  duration_hours decimal(3,1) NOT NULL CHECK (duration_hours > 0),
  total_coins integer NOT NULL CHECK (total_coins >= 1200),
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'in_progress', 'completed', 'cancelled', 'disputed')),
  coins_held_in_escrow boolean DEFAULT false,
  student_completed boolean DEFAULT false,
  tutor_completed boolean DEFAULT false,
  cancellation_reason text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  approved_at timestamptz,
  started_at timestamptz,
  completed_at timestamptz,
  cancelled_at timestamptz
);

-- Favorites table
CREATE TABLE IF NOT EXISTS favorites (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  tutor_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE(student_id, tutor_id)
);

-- Enable Row Level Security
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;

-- RLS Policies for matches
CREATE POLICY "Students can view own matches"
  ON matches FOR SELECT
  TO authenticated
  USING (auth.uid() = student_id);

CREATE POLICY "Tutors can view received matches"
  ON matches FOR SELECT
  TO authenticated
  USING (auth.uid() = tutor_id);

CREATE POLICY "Students can create matches"
  ON matches FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Tutors can update received matches"
  ON matches FOR UPDATE
  TO authenticated
  USING (auth.uid() = tutor_id)
  WITH CHECK (auth.uid() = tutor_id);

CREATE POLICY "Students can cancel own matches"
  ON matches FOR UPDATE
  TO authenticated
  USING (auth.uid() = student_id)
  WITH CHECK (auth.uid() = student_id);

-- RLS Policies for lessons
CREATE POLICY "Students can view own lessons"
  ON lessons FOR SELECT
  TO authenticated
  USING (auth.uid() = student_id);

CREATE POLICY "Tutors can view own lessons"
  ON lessons FOR SELECT
  TO authenticated
  USING (auth.uid() = tutor_id);

CREATE POLICY "Students can create lesson requests"
  ON lessons FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Students can update own lessons"
  ON lessons FOR UPDATE
  TO authenticated
  USING (auth.uid() = student_id)
  WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Tutors can update own lessons"
  ON lessons FOR UPDATE
  TO authenticated
  USING (auth.uid() = tutor_id)
  WITH CHECK (auth.uid() = tutor_id);

-- RLS Policies for favorites
CREATE POLICY "Students can view own favorites"
  ON favorites FOR SELECT
  TO authenticated
  USING (auth.uid() = student_id);

CREATE POLICY "Students can add favorites"
  ON favorites FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = student_id);

CREATE POLICY "Students can remove favorites"
  ON favorites FOR DELETE
  TO authenticated
  USING (auth.uid() = student_id);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_matches_student ON matches(student_id);
CREATE INDEX IF NOT EXISTS idx_matches_tutor ON matches(tutor_id);
CREATE INDEX IF NOT EXISTS idx_matches_status ON matches(status);
CREATE INDEX IF NOT EXISTS idx_lessons_student ON lessons(student_id);
CREATE INDEX IF NOT EXISTS idx_lessons_tutor ON lessons(tutor_id);
CREATE INDEX IF NOT EXISTS idx_lessons_match ON lessons(match_id);
CREATE INDEX IF NOT EXISTS idx_lessons_status ON lessons(status);
CREATE INDEX IF NOT EXISTS idx_lessons_scheduled_date ON lessons(scheduled_date);
CREATE INDEX IF NOT EXISTS idx_favorites_student ON favorites(student_id);
CREATE INDEX IF NOT EXISTS idx_favorites_tutor ON favorites(tutor_id);

-- Triggers for updated_at
CREATE TRIGGER update_matches_updated_at BEFORE UPDATE ON matches
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_lessons_updated_at BEFORE UPDATE ON lessons
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

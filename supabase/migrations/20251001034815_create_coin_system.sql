/*
  # Coin System Schema

  ## Description
  Creates tables for coin management, transactions, and payouts.

  ## Tables Created
  
  ### 1. coin_transactions
    - Records all coin movements (purchases, matching fees, escrow, transfers, withdrawals)
    - Provides audit trail for all financial operations
  
  ### 2. payout_requests
    - Tracks tutor payout requests
    - Manages payout status and fees
  
  ## Security
    - RLS enabled on all tables
    - Users can only view their own transactions
    - Strict access control for financial data
  
  ## Important Notes
    - Coin balance is tracked in student_profiles.coins
    - All coin operations must create corresponding transaction records
    - Escrow system uses transaction records for audit trail
*/

-- Coin transactions table
CREATE TABLE IF NOT EXISTS coin_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  transaction_type text NOT NULL CHECK (transaction_type IN (
    'purchase',
    'matching_fee',
    'lesson_hold',
    'lesson_release',
    'lesson_payment',
    'refund',
    'payout',
    'payout_fee'
  )),
  amount integer NOT NULL,
  balance_after integer NOT NULL CHECK (balance_after >= 0),
  description text,
  related_match_id uuid REFERENCES matches(id),
  related_lesson_id uuid REFERENCES lessons(id),
  related_payout_id uuid,
  metadata jsonb DEFAULT '{}',
  created_at timestamptz DEFAULT now()
);

-- Payout requests table
CREATE TABLE IF NOT EXISTS payout_requests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tutor_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount_coins integer NOT NULL CHECK (amount_coins > 0),
  amount_jpy integer NOT NULL CHECK (amount_jpy > 0),
  fee_coins integer NOT NULL DEFAULT 0,
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'cancelled', 'failed')),
  bank_account_info jsonb,
  processed_by uuid REFERENCES users(id),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  processed_at timestamptz,
  notes text
);

-- Enable Row Level Security
ALTER TABLE coin_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;

-- RLS Policies for coin_transactions
CREATE POLICY "Users can view own transactions"
  ON coin_transactions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own transactions"
  ON coin_transactions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

-- RLS Policies for payout_requests
CREATE POLICY "Tutors can view own payout requests"
  ON payout_requests FOR SELECT
  TO authenticated
  USING (auth.uid() = tutor_id);

CREATE POLICY "Tutors can create payout requests"
  ON payout_requests FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = tutor_id);

CREATE POLICY "Tutors can cancel own pending payouts"
  ON payout_requests FOR UPDATE
  TO authenticated
  USING (auth.uid() = tutor_id AND status = 'pending')
  WITH CHECK (auth.uid() = tutor_id AND status IN ('pending', 'cancelled'));

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_coin_transactions_user ON coin_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_type ON coin_transactions(transaction_type);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_created ON coin_transactions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_coin_transactions_match ON coin_transactions(related_match_id) WHERE related_match_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_coin_transactions_lesson ON coin_transactions(related_lesson_id) WHERE related_lesson_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_payout_requests_tutor ON payout_requests(tutor_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON payout_requests(status);
CREATE INDEX IF NOT EXISTS idx_payout_requests_created ON payout_requests(created_at DESC);

-- Trigger for payout_requests updated_at
CREATE TRIGGER update_payout_requests_updated_at BEFORE UPDATE ON payout_requests
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Function to calculate payout fee
CREATE OR REPLACE FUNCTION calculate_payout_fee(amount_jpy integer)
RETURNS integer AS $$
BEGIN
  IF amount_jpy > 100000 THEN
    RETURN 0;
  ELSE
    RETURN 300;
  END IF;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to handle coin purchase
CREATE OR REPLACE FUNCTION record_coin_purchase(
  p_user_id uuid,
  p_amount integer,
  p_description text DEFAULT NULL
)
RETURNS uuid AS $$
DECLARE
  v_current_balance integer;
  v_new_balance integer;
  v_transaction_id uuid;
BEGIN
  SELECT coins INTO v_current_balance
  FROM student_profiles
  WHERE id = p_user_id;
  
  IF v_current_balance IS NULL THEN
    RAISE EXCEPTION 'Student profile not found';
  END IF;
  
  v_new_balance := v_current_balance + p_amount;
  
  UPDATE student_profiles
  SET coins = v_new_balance
  WHERE id = p_user_id;
  
  INSERT INTO coin_transactions (
    user_id,
    transaction_type,
    amount,
    balance_after,
    description
  ) VALUES (
    p_user_id,
    'purchase',
    p_amount,
    v_new_balance,
    COALESCE(p_description, 'Coin purchase')
  ) RETURNING id INTO v_transaction_id;
  
  RETURN v_transaction_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

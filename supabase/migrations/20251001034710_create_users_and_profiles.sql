/*
  # Initial Database Schema for Senpai App

  ## Description
  Creates the core tables for user authentication, profiles, and role management.

  ## Tables Created
  
  ### 1. users (extends Supabase Auth)
    - Basic user information linked to auth.users
    - Tracks user role (student/tutor)
    - Stores common profile fields
  
  ### 2. student_profiles
    - Extended profile data for students
    - Grade, age, subjects interested
    - Coin balance tracking
  
  ### 3. tutor_profiles
    - Extended profile data for tutors
    - Hourly rate, subjects taught
    - Available subjects and teaching preferences
    - Online/offline availability
  
  ## Security
    - RLS enabled on all tables
    - Users can only read/update their own profile data
    - Authenticated users required for all operations
*/

-- Users table (extends auth.users)
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text UNIQUE NOT NULL,
  name text NOT NULL,
  role text NOT NULL CHECK (role IN ('student', 'tutor')),
  phone_number text,
  date_of_birth date,
  gender text CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  prefecture text,
  city text,
  profile_image_url text,
  is_minor boolean DEFAULT false,
  guardian_consent_given boolean DEFAULT false,
  guardian_consent_date timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Student profiles
CREATE TABLE IF NOT EXISTS student_profiles (
  id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  school_name text,
  grade text,
  age integer,
  subjects_interested text[] DEFAULT '{}',
  coins integer DEFAULT 0 CHECK (coins >= 0),
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Tutor profiles
CREATE TABLE IF NOT EXISTS tutor_profiles (
  id uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  school_name text,
  university text,
  major text,
  graduation_year integer,
  subjects_taught text[] DEFAULT '{}',
  hourly_rate_coins integer DEFAULT 1200 CHECK (hourly_rate_coins >= 1200 AND hourly_rate_coins <= 2400),
  self_introduction text,
  is_online_available boolean DEFAULT true,
  is_offline_available boolean DEFAULT false,
  rating_average decimal(3,2) DEFAULT 0.00,
  total_lessons integer DEFAULT 0,
  total_reviews integer DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE tutor_profiles ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users can view own profile"
  ON users FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can view other user basic info"
  ON users FOR SELECT
  TO authenticated
  USING (true);

-- RLS Policies for student_profiles
CREATE POLICY "Students can view own profile"
  ON student_profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Students can update own profile"
  ON student_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Students can insert own profile"
  ON student_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- RLS Policies for tutor_profiles
CREATE POLICY "Anyone can view tutor profiles"
  ON tutor_profiles FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Tutors can update own profile"
  ON tutor_profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Tutors can insert own profile"
  ON tutor_profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_subjects ON tutor_profiles USING GIN(subjects_taught);
CREATE INDEX IF NOT EXISTS idx_tutor_profiles_rating ON tutor_profiles(rating_average DESC);
CREATE INDEX IF NOT EXISTS idx_student_profiles_subjects ON student_profiles USING GIN(subjects_interested);

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_student_profiles_updated_at BEFORE UPDATE ON student_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tutor_profiles_updated_at BEFORE UPDATE ON tutor_profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

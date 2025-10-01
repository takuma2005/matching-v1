import { createClient } from '@supabase/supabase-js';
import AsyncStorage from '@react-native-async-storage/async-storage';
import 'react-native-url-polyfill/auto';

const supabaseUrl = process.env.EXPO_PUBLIC_SUPABASE_URL || '';
const supabaseAnonKey = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY || '';

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Supabase credentials not found in environment variables');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    storage: AsyncStorage,
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});

export type Database = {
  public: {
    Tables: {
      users: {
        Row: {
          id: string;
          email: string;
          name: string;
          role: 'student' | 'tutor';
          phone_number: string | null;
          date_of_birth: string | null;
          gender: string | null;
          prefecture: string | null;
          city: string | null;
          profile_image_url: string | null;
          is_minor: boolean;
          guardian_consent_given: boolean;
          guardian_consent_date: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          email: string;
          name: string;
          role: 'student' | 'tutor';
          phone_number?: string | null;
          date_of_birth?: string | null;
          gender?: string | null;
          prefecture?: string | null;
          city?: string | null;
          profile_image_url?: string | null;
          is_minor?: boolean;
          guardian_consent_given?: boolean;
          guardian_consent_date?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          email?: string;
          name?: string;
          role?: 'student' | 'tutor';
          phone_number?: string | null;
          date_of_birth?: string | null;
          gender?: string | null;
          prefecture?: string | null;
          city?: string | null;
          profile_image_url?: string | null;
          is_minor?: boolean;
          guardian_consent_given?: boolean;
          guardian_consent_date?: string | null;
          created_at?: string;
          updated_at?: string;
        };
      };
      student_profiles: {
        Row: {
          id: string;
          school_name: string | null;
          grade: string | null;
          age: number | null;
          subjects_interested: string[];
          coins: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          school_name?: string | null;
          grade?: string | null;
          age?: number | null;
          subjects_interested?: string[];
          coins?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          school_name?: string | null;
          grade?: string | null;
          age?: number | null;
          subjects_interested?: string[];
          coins?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
      tutor_profiles: {
        Row: {
          id: string;
          school_name: string | null;
          university: string | null;
          major: string | null;
          graduation_year: number | null;
          subjects_taught: string[];
          hourly_rate_coins: number;
          self_introduction: string | null;
          is_online_available: boolean;
          is_offline_available: boolean;
          rating_average: number;
          total_lessons: number;
          total_reviews: number;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          school_name?: string | null;
          university?: string | null;
          major?: string | null;
          graduation_year?: number | null;
          subjects_taught?: string[];
          hourly_rate_coins?: number;
          self_introduction?: string | null;
          is_online_available?: boolean;
          is_offline_available?: boolean;
          rating_average?: number;
          total_lessons?: number;
          total_reviews?: number;
          created_at?: string;
          updated_at?: string;
        };
        Update: {
          id?: string;
          school_name?: string | null;
          university?: string | null;
          major?: string | null;
          graduation_year?: number | null;
          subjects_taught?: string[];
          hourly_rate_coins?: number;
          self_introduction?: string | null;
          is_online_available?: boolean;
          is_offline_available?: boolean;
          rating_average?: number;
          total_lessons?: number;
          total_reviews?: number;
          created_at?: string;
          updated_at?: string;
        };
      };
    };
  };
};

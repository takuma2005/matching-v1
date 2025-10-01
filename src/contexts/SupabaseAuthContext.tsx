import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { Session, User as SupabaseUser } from '@supabase/supabase-js';
import { supabase, Database } from '@/lib/supabase';

type UserProfile = Database['public']['Tables']['users']['Row'];
type StudentProfile = Database['public']['Tables']['student_profiles']['Row'];
type TutorProfile = Database['public']['Tables']['tutor_profiles']['Row'];

interface SupabaseAuthContextType {
  session: Session | null;
  user: UserProfile | null;
  studentProfile: StudentProfile | null;
  tutorProfile: TutorProfile | null;
  isLoading: boolean;
  signUp: (email: string, password: string, name: string, role: 'student' | 'tutor') => Promise<{ success: boolean; error?: string }>;
  signIn: (email: string, password: string) => Promise<{ success: boolean; error?: string }>;
  signOut: () => Promise<void>;
  updateProfile: (updates: Partial<UserProfile>) => Promise<{ success: boolean; error?: string }>;
  refreshProfile: () => Promise<void>;
}

const SupabaseAuthContext = createContext<SupabaseAuthContextType | undefined>(undefined);

export function useSupabaseAuth() {
  const context = useContext(SupabaseAuthContext);
  if (context === undefined) {
    throw new Error('useSupabaseAuth must be used within a SupabaseAuthProvider');
  }
  return context;
}

interface SupabaseAuthProviderProps {
  children: ReactNode;
}

export function SupabaseAuthProvider({ children }: SupabaseAuthProviderProps) {
  const [session, setSession] = useState<Session | null>(null);
  const [user, setUser] = useState<UserProfile | null>(null);
  const [studentProfile, setStudentProfile] = useState<StudentProfile | null>(null);
  const [tutorProfile, setTutorProfile] = useState<TutorProfile | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const loadUserProfile = async (userId: string) => {
    try {
      const { data: userProfile, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

      if (userError) throw userError;

      if (userProfile) {
        setUser(userProfile);

        if (userProfile.role === 'student') {
          const { data: studentData, error: studentError } = await supabase
            .from('student_profiles')
            .select('*')
            .eq('id', userId)
            .maybeSingle();

          if (!studentError && studentData) {
            setStudentProfile(studentData);
          }
        } else if (userProfile.role === 'tutor') {
          const { data: tutorData, error: tutorError } = await supabase
            .from('tutor_profiles')
            .select('*')
            .eq('id', userId)
            .maybeSingle();

          if (!tutorError && tutorData) {
            setTutorProfile(tutorData);
          }
        }
      }
    } catch (error) {
      console.error('Error loading user profile:', error);
    }
  };

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      if (session?.user) {
        loadUserProfile(session.user.id).finally(() => setIsLoading(false));
      } else {
        setIsLoading(false);
      }
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      if (session?.user) {
        loadUserProfile(session.user.id);
      } else {
        setUser(null);
        setStudentProfile(null);
        setTutorProfile(null);
      }
    });

    return () => subscription.unsubscribe();
  }, []);

  const signUp = async (email: string, password: string, name: string, role: 'student' | 'tutor') => {
    try {
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password,
      });

      if (authError) throw authError;
      if (!authData.user) throw new Error('No user returned from signup');

      const { error: userError } = await supabase.from('users').insert({
        id: authData.user.id,
        email,
        name,
        role,
      });

      if (userError) throw userError;

      if (role === 'student') {
        const { error: studentError } = await supabase.from('student_profiles').insert({
          id: authData.user.id,
          coins: 0,
        });
        if (studentError) throw studentError;
      } else if (role === 'tutor') {
        const { error: tutorError } = await supabase.from('tutor_profiles').insert({
          id: authData.user.id,
          hourly_rate_coins: 1200,
        });
        if (tutorError) throw tutorError;
      }

      return { success: true };
    } catch (error: any) {
      console.error('Sign up error:', error);
      return { success: false, error: error.message };
    }
  };

  const signIn = async (email: string, password: string) => {
    try {
      const { error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) throw error;

      return { success: true };
    } catch (error: any) {
      console.error('Sign in error:', error);
      return { success: false, error: error.message };
    }
  };

  const signOut = async () => {
    try {
      await supabase.auth.signOut();
      setUser(null);
      setStudentProfile(null);
      setTutorProfile(null);
    } catch (error) {
      console.error('Sign out error:', error);
    }
  };

  const updateProfile = async (updates: Partial<UserProfile>) => {
    if (!user) return { success: false, error: 'No user logged in' };

    try {
      const { error } = await supabase
        .from('users')
        .update(updates)
        .eq('id', user.id);

      if (error) throw error;

      await refreshProfile();
      return { success: true };
    } catch (error: any) {
      console.error('Update profile error:', error);
      return { success: false, error: error.message };
    }
  };

  const refreshProfile = async () => {
    if (session?.user) {
      await loadUserProfile(session.user.id);
    }
  };

  const value: SupabaseAuthContextType = {
    session,
    user,
    studentProfile,
    tutorProfile,
    isLoading,
    signUp,
    signIn,
    signOut,
    updateProfile,
    refreshProfile,
  };

  return (
    <SupabaseAuthContext.Provider value={value}>
      {children}
    </SupabaseAuthContext.Provider>
  );
}

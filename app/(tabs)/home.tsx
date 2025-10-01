import { useSupabaseAuth } from '@/contexts/SupabaseAuthContext';
import StudentHomeScreen from '@/screens/home/StudentHomeScreen';
import TutorHomeScreen from '@/screens/home/TutorHomeScreen';

export default function HomeTab() {
  const { user } = useSupabaseAuth();

  if (user?.role === 'student') {
    return <StudentHomeScreen />;
  }

  return <TutorHomeScreen />;
}

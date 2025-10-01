import { useSupabaseAuth } from '@/contexts/SupabaseAuthContext';
import StudentLessonListScreen from '@/screens/lessons/student/StudentLessonListScreen';
import TutorLessonListScreen from '@/screens/lessons/tutor/TutorLessonListScreen';

export default function LessonsTab() {
  const { user } = useSupabaseAuth();

  if (user?.role === 'student') {
    return <StudentLessonListScreen />;
  }

  return <TutorLessonListScreen />;
}

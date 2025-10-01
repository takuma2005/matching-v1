import { Stack } from 'expo-router';

export default function AuthLayout() {
  return (
    <Stack screenOptions={{ headerShown: false }}>
      <Stack.Screen name="role-selection" />
      <Stack.Screen name="phone-verification" />
      <Stack.Screen name="profile-setup" />
      <Stack.Screen name="profile-completion" />
    </Stack>
  );
}

import React from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';

import StudentTabNavigator from './StudentTabNavigator';
import TutorTabNavigator from './TutorTabNavigator';
import { useAuth } from '../contexts/AuthContext';
import { colors } from '../styles/theme';

export default function RoleBasedNavigator() {
  const { user, role, isLoading } = useAuth();

  // ローディング中のスプラッシュ画面
  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color={colors.primary} />
      </View>
    );
  }

  // ログイン済みの場合は役割に応じたタブナビゲーションを表示
  if (user && role === 'student') {
    return <StudentTabNavigator />;
  }

  if (user && role === 'tutor') {
    return <TutorTabNavigator />;
  }

  // デフォルトは学生タブ
  return <StudentTabNavigator />;
}

const styles = StyleSheet.create({
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: colors.background,
  },
});

import { MaterialIcons } from '@expo/vector-icons';
import { useRouter } from 'expo-router';
import React from 'react';
import { View, Text, StyleSheet, TouchableOpacity } from 'react-native';

import { colors, spacing, typography, borderRadius, shadows } from '../../styles/theme';

export default function RoleSelectionScreen() {
  const router = useRouter();
  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <MaterialIcons name="school" size={64} color={colors.primary} />
        <Text style={styles.title}>センパイ</Text>
        <Text style={styles.subtitle}>あなたの役割を選択してください</Text>
      </View>

      <View style={styles.content}>
        <TouchableOpacity
          style={[styles.roleCard, styles.studentCard]}
          onPress={() => router.push({ pathname: '/(auth)/phone-verification', params: { role: 'student' } })}
          activeOpacity={0.8}
        >
          <MaterialIcons name="school" size={48} color={colors.primary} />
          <Text style={styles.roleTitle}>後輩として利用</Text>
          <Text style={styles.roleDescription}>
            理想の先輩を見つけて学習をサポートしてもらいましょう
          </Text>
        </TouchableOpacity>

        <TouchableOpacity
          style={[styles.roleCard, styles.tutorCard]}
          onPress={() => router.push({ pathname: '/(auth)/phone-verification', params: { role: 'tutor' } })}
          activeOpacity={0.8}
        >
          <MaterialIcons name="person" size={48} color={colors.secondary} />
          <Text style={[styles.roleTitle, styles.tutorTitle]}>先輩として登録</Text>
          <Text style={styles.roleDescription}>
            あなたの知識と経験で後輩の成長をサポートしませんか
          </Text>
        </TouchableOpacity>
      </View>

      <View style={styles.footer}>
        <Text style={styles.footerText}>いつでも設定から役割を変更できます</Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  header: {
    alignItems: 'center',
    paddingTop: spacing.xxl * 2,
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.xl,
  },
  title: {
    fontSize: typography.fontSizes.xxxxl,
    fontWeight: typography.fontWeights.bold,
    color: colors.gray900,
    marginTop: spacing.md,
    textAlign: 'center',
  },
  subtitle: {
    fontSize: typography.fontSizes.lg,
    color: colors.gray600,
    marginTop: spacing.sm,
    textAlign: 'center',
  },
  content: {
    flex: 1,
    paddingHorizontal: spacing.lg,
    justifyContent: 'center',
  },
  roleCard: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.lg,
    padding: spacing.xl,
    marginVertical: spacing.md,
    alignItems: 'center',
    ...shadows.md,
  },
  studentCard: {
    borderWidth: 2,
    borderColor: colors.primary,
  },
  tutorCard: {
    borderWidth: 2,
    borderColor: colors.secondary,
  },
  roleTitle: {
    fontSize: typography.fontSizes.xl,
    fontWeight: typography.fontWeights.bold,
    color: colors.gray900,
    marginTop: spacing.md,
    marginBottom: spacing.sm,
  },
  tutorTitle: {
    color: colors.gray900,
  },
  roleDescription: {
    fontSize: typography.fontSizes.md,
    color: colors.gray600,
    textAlign: 'center',
    lineHeight: typography.lineHeights.relaxed * typography.fontSizes.md,
  },
  footer: {
    padding: spacing.lg,
    alignItems: 'center',
  },
  footerText: {
    fontSize: typography.fontSizes.sm,
    color: colors.gray500,
    textAlign: 'center',
  },
});

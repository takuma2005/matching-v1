import { MaterialIcons } from '@expo/vector-icons';
import { useLocalSearchParams, useRouter } from 'expo-router';
import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  Alert,
  ScrollView,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import { useSupabaseAuth } from '@/contexts/SupabaseAuthContext';

import { colors, spacing, typography, borderRadius, shadows } from '../../styles/theme';

export default function ProfileSetupScreen() {
  const params = useLocalSearchParams();
  const router = useRouter();
  const { signUp } = useSupabaseAuth();
  const role = (params.role as 'student' | 'tutor') || 'student';
  const phoneNumber = params.phoneNumber as string;
  const [name, setName] = useState('');
  const [age, setAge] = useState('');
  const [location, setLocation] = useState('');
  const [subjects, setSubjects] = useState('');
  const [introduction, setIntroduction] = useState('');
  const [loading, setLoading] = useState(false);

  const handleComplete = async () => {
    if (!name.trim()) {
      Alert.alert('エラー', '名前を入力してください');
      return;
    }
    if (!age.trim() || isNaN(Number(age)) || Number(age) < 10 || Number(age) > 100) {
      Alert.alert('エラー', '正しい年齢を入力してください（10-100）');
      return;
    }
    if (!location.trim()) {
      Alert.alert('エラー', '居住地を入力してください');
      return;
    }

    setLoading(true);

    try {
      const email = phoneNumber.replace(/\D/g, '') + '@senpai.app';
      const password = 'temp' + Math.random().toString(36).substr(2, 9);

      const result = await signUp(email, password, name.trim(), role);

      if (result.success) {
        router.replace('/(tabs)/home');
      } else {
        Alert.alert('エラー', result.error || '登録に失敗しました');
      }
    } catch (error: any) {
      Alert.alert('エラー', error.message || '登録に失敗しました');
    } finally {
      setLoading(false);
    }
  };

  const roleText = role === 'student' ? '後輩' : '先輩';

  return (
    <KeyboardAvoidingView
      style={styles.container}
      behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
    >
      <ScrollView style={styles.scrollContainer} showsVerticalScrollIndicator={false}>
        <View style={styles.header}>
          <MaterialIcons name="person-add" size={48} color={colors.primary} />
          <Text style={styles.title}>プロフィール設定</Text>
          <Text style={styles.subtitle}>{roleText}としてのプロフィールを設定してください</Text>
        </View>

        <View style={styles.content}>
          <View style={styles.inputGroup}>
            <Text style={styles.label}>名前 *</Text>
            <TextInput
              style={styles.input}
              placeholder="山田太郎"
              value={name}
              onChangeText={setName}
              maxLength={20}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>年齢 *</Text>
            <TextInput
              style={styles.input}
              placeholder="20"
              value={age}
              onChangeText={setAge}
              keyboardType="numeric"
              maxLength={3}
            />
          </View>

          <View style={styles.inputGroup}>
            <Text style={styles.label}>居住地 *</Text>
            <TextInput
              style={styles.input}
              placeholder="東京都渋谷区"
              value={location}
              onChangeText={setLocation}
              maxLength={50}
            />
          </View>

          {role === 'tutor' && (
            <View style={styles.inputGroup}>
              <Text style={styles.label}>指導可能科目</Text>
              <TextInput
                style={styles.input}
                placeholder="数学,英語,物理（カンマ区切り）"
                value={subjects}
                onChangeText={setSubjects}
                maxLength={100}
              />
              <Text style={styles.hint}>指導できる科目をカンマ（,）で区切って入力してください</Text>
            </View>
          )}

          <View style={styles.inputGroup}>
            <Text style={styles.label}>自己紹介</Text>
            <TextInput
              style={[styles.input, styles.textArea]}
              placeholder={
                role === 'student'
                  ? '学習目標や希望する指導スタイルなどを書いてください'
                  : '指導経験や得意分野などを書いてください'
              }
              value={introduction}
              onChangeText={setIntroduction}
              multiline
              numberOfLines={4}
              maxLength={200}
            />
            <Text style={styles.characterCount}>{introduction.length}/200</Text>
          </View>

          <TouchableOpacity
            style={[styles.button, loading && styles.buttonDisabled]}
            onPress={handleComplete}
            disabled={loading}
          >
            <Text style={styles.buttonText}>{loading ? '登録中...' : '登録を完了'}</Text>
          </TouchableOpacity>
        </View>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.background,
  },
  scrollContainer: {
    flex: 1,
  },
  header: {
    alignItems: 'center',
    paddingTop: spacing.xxl,
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.lg,
  },
  title: {
    fontSize: typography.fontSizes.xxxl,
    fontWeight: typography.fontWeights.bold,
    color: colors.gray900,
    marginTop: spacing.md,
  },
  subtitle: {
    fontSize: typography.fontSizes.md,
    color: colors.gray600,
    marginTop: spacing.sm,
    textAlign: 'center',
    lineHeight: typography.lineHeights.relaxed * typography.fontSizes.md,
  },
  content: {
    paddingHorizontal: spacing.lg,
    paddingBottom: spacing.xxl,
  },
  inputGroup: {
    marginBottom: spacing.lg,
  },
  label: {
    fontSize: typography.fontSizes.md,
    fontWeight: typography.fontWeights.medium,
    color: colors.gray700,
    marginBottom: spacing.sm,
  },
  input: {
    backgroundColor: colors.surface,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    fontSize: typography.fontSizes.md,
    borderWidth: 1,
    borderColor: colors.gray300,
    ...shadows.sm,
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  hint: {
    fontSize: typography.fontSizes.sm,
    color: colors.gray500,
    marginTop: spacing.xs,
  },
  characterCount: {
    fontSize: typography.fontSizes.sm,
    color: colors.gray400,
    textAlign: 'right',
    marginTop: spacing.xs,
  },
  button: {
    backgroundColor: colors.primary,
    borderRadius: borderRadius.md,
    padding: spacing.md,
    alignItems: 'center',
    marginTop: spacing.lg,
    ...shadows.sm,
  },
  buttonDisabled: {
    backgroundColor: colors.gray300,
  },
  buttonText: {
    color: colors.white,
    fontSize: typography.fontSizes.md,
    fontWeight: typography.fontWeights.semibold,
  },
});

import { createStackNavigator } from '@react-navigation/stack';
import React from 'react';

import HomeScreen from '../screens/HomeScreen';
import TutorDetailScreen from '../screens/TutorDetailScreen';
import NotificationScreen from '../screens/NotificationScreen';

export type HomeStackParamList = {
  HomeMain: undefined;
  TutorDetail: { tutorId: string };
  Notifications: undefined;
};

const Stack = createStackNavigator<HomeStackParamList>();

export default function HomeStackNavigator() {
  return (
    <Stack.Navigator
      screenOptions={{
        headerShown: false,
      }}
    >
      <Stack.Screen name="HomeMain" component={HomeScreen} />
      <Stack.Screen name="TutorDetail" component={TutorDetailScreen} />
      <Stack.Screen name="Notifications" component={NotificationScreen} />
    </Stack.Navigator>
  );
}

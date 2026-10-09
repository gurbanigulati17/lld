import { StatusBar } from 'expo-status-bar';
import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  ActivityIndicator,
  FlatList,
  Linking,
  Pressable,
  RefreshControl,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  useColorScheme,
} from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

import { FeedItem, fetchAllFeeds, timeAgo } from './src/feed';
import { ModelId, PROVIDERS } from './src/sources';

type Filter = 'all' | ModelId;

const providerById = Object.fromEntries(PROVIDERS.map((p) => [p.id, p]));

const LIGHT = { bg: '#F6F7F9', card: '#FFFFFF', text: '#111418', muted: '#5F6670', border: '#E3E6EA' };
const DARK = { bg: '#0E1013', card: '#181B20', text: '#F1F3F5', muted: '#9AA1AB', border: '#2A2F36' };

function FeedScreen() {
  const theme = useColorScheme() === 'dark' ? DARK : LIGHT;
  const [items, setItems] = useState<FeedItem[]>([]);
  const [failed, setFailed] = useState<string[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [filter, setFilter] = useState<Filter>('all');
  const [query, setQuery] = useState('');

  const load = useCallback(async () => {
    const result = await fetchAllFeeds();
    setItems(result.items);
    setFailed(result.failed);
  }, []);

  useEffect(() => {
    load().finally(() => setLoading(false));
  }, [load]);

  const onRefresh = useCallback(async () => {
    setRefreshing(true);
    await load();
    setRefreshing(false);
  }, [load]);

  const visible = useMemo(() => {
    const q = query.trim().toLowerCase();
    return items.filter(
      (item) =>
        (filter === 'all' || item.model === filter) &&
        (!q || item.title.toLowerCase().includes(q) || item.summary.toLowerCase().includes(q)),
    );
  }, [items, filter, query]);

  const chips: { id: Filter; label: string; color: string }[] = [
    { id: 'all', label: 'All', color: theme.text },
    ...PROVIDERS.map((p) => ({ id: p.id, label: p.label, color: p.color })),
  ];

  return (
    <SafeAreaView style={[styles.screen, { backgroundColor: theme.bg }]} edges={['top', 'left', 'right']}>
      <StatusBar style={theme === DARK ? 'light' : 'dark'} />
      <View style={styles.header}>
        <Text style={[styles.title, { color: theme.text }]}>AI Buzz Feed</Text>
        <Text style={[styles.subtitle, { color: theme.muted }]}>Latest rollouts from Claude, ChatGPT, Gemini & Grok</Text>
        <TextInput
          value={query}
          onChangeText={setQuery}
          placeholder="Search updates…"
          placeholderTextColor={theme.muted}
          style={[styles.search, { backgroundColor: theme.card, color: theme.text, borderColor: theme.border }]}
          clearButtonMode="while-editing"
        />
        <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.chips}>
          {chips.map((chip) => {
            const active = filter === chip.id;
            return (
              <Pressable
                key={chip.id}
                onPress={() => setFilter(chip.id)}
                style={[
                  styles.chip,
                  { borderColor: active ? chip.color : theme.border, backgroundColor: active ? chip.color : theme.card },
                ]}
              >
                <Text style={[styles.chipText, { color: active ? (chip.id === 'all' ? theme.bg : '#FFF') : theme.text }]}>
                  {chip.label}
                </Text>
              </Pressable>
            );
          })}
        </ScrollView>
      </View>

      {loading ? (
        <ActivityIndicator style={styles.loader} size="large" />
      ) : (
        <FlatList
          data={visible}
          keyExtractor={(item) => item.id}
          contentContainerStyle={styles.list}
          refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
          ListHeaderComponent={
            failed.length > 0 ? (
              <Text style={[styles.warning, { color: theme.muted }]}>Couldn't reach: {failed.join(', ')}</Text>
            ) : null
          }
          ListEmptyComponent={
            <Text style={[styles.empty, { color: theme.muted }]}>No updates found. Pull down to refresh.</Text>
          }
          renderItem={({ item }) => {
            const provider = providerById[item.model];
            return (
              <Pressable
                onPress={() => Linking.openURL(item.link)}
                style={({ pressed }) => [
                  styles.card,
                  { backgroundColor: theme.card, borderColor: theme.border, opacity: pressed ? 0.7 : 1 },
                ]}
              >
                <View style={styles.cardMeta}>
                  <View style={[styles.badge, { backgroundColor: provider.color }]}>
                    <Text style={styles.badgeText}>{provider.label}</Text>
                  </View>
                  <Text style={[styles.metaText, { color: theme.muted }]} numberOfLines={1}>
                    {item.source} · {timeAgo(item.publishedAt)}
                  </Text>
                </View>
                <Text style={[styles.cardTitle, { color: theme.text }]}>{item.title}</Text>
                {item.summary ? (
                  <Text style={[styles.summary, { color: theme.muted }]} numberOfLines={3}>
                    {item.summary}
                  </Text>
                ) : null}
              </Pressable>
            );
          }}
        />
      )}
    </SafeAreaView>
  );
}

export default function App() {
  return (
    <SafeAreaProvider>
      <FeedScreen />
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1 },
  header: { paddingHorizontal: 16, paddingTop: 8 },
  title: { fontSize: 28, fontWeight: '800' },
  subtitle: { fontSize: 14, marginTop: 2 },
  search: { marginTop: 12, borderWidth: 1, borderRadius: 12, paddingHorizontal: 12, paddingVertical: 10, fontSize: 15 },
  chips: { gap: 8, paddingVertical: 12 },
  chip: { borderWidth: 1, borderRadius: 999, paddingHorizontal: 14, paddingVertical: 7 },
  chipText: { fontSize: 14, fontWeight: '600' },
  loader: { marginTop: 48 },
  list: { paddingHorizontal: 16, paddingBottom: 32, gap: 12 },
  warning: { fontSize: 12, marginBottom: 4 },
  empty: { textAlign: 'center', marginTop: 48 },
  card: { borderWidth: 1, borderRadius: 14, padding: 14 },
  cardMeta: { flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 8 },
  badge: { borderRadius: 6, paddingHorizontal: 8, paddingVertical: 2 },
  badgeText: { color: '#FFF', fontSize: 12, fontWeight: '700' },
  metaText: { fontSize: 12, flexShrink: 1 },
  cardTitle: { fontSize: 16, fontWeight: '600', lineHeight: 22 },
  summary: { fontSize: 14, lineHeight: 20, marginTop: 6 },
});

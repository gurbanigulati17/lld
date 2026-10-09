export type ModelId = 'claude' | 'openai' | 'gemini' | 'grok';

export interface FeedSource {
  model: ModelId;
  name: string;
  url: string;
}

export interface Provider {
  id: ModelId;
  label: string;
  company: string;
  color: string;
}

export const PROVIDERS: Provider[] = [
  { id: 'claude', label: 'Claude', company: 'Anthropic', color: '#D97757' },
  { id: 'openai', label: 'ChatGPT', company: 'OpenAI', color: '#10A37F' },
  { id: 'gemini', label: 'Gemini', company: 'Google', color: '#4285F4' },
  { id: 'grok', label: 'Grok', company: 'xAI', color: '#8B5CF6' },
];

const googleNews = (query: string) =>
  `https://news.google.com/rss/search?q=${encodeURIComponent(query)}&hl=en-US&gl=US&ceid=US:en`;

// Official blogs where an RSS feed exists, plus Google News searches focused on
// launches/rollouts so every provider has coverage.
export const SOURCES: FeedSource[] = [
  { model: 'claude', name: 'Google News', url: googleNews('Anthropic Claude (launch OR release OR rollout OR feature OR update) when:30d') },
  { model: 'openai', name: 'OpenAI News', url: 'https://openai.com/news/rss.xml' },
  { model: 'openai', name: 'Google News', url: googleNews('OpenAI ChatGPT (launch OR release OR rollout OR feature OR update) when:30d') },
  { model: 'gemini', name: 'Google AI Blog', url: 'https://blog.google/technology/ai/rss/' },
  { model: 'gemini', name: 'Google News', url: googleNews('Google Gemini (launch OR release OR rollout OR feature OR update) when:30d') },
  { model: 'grok', name: 'Google News', url: googleNews('xAI Grok (launch OR release OR rollout OR feature OR update) when:30d') },
];

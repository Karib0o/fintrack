-- ═══════════════════════════════════════════════════════════
--  FINTRACK — Script de configuration Supabase
--  Copiez-collez ce script dans l'éditeur SQL de Supabase
--  (Database → SQL Editor → New query → Coller → Run)
-- ═══════════════════════════════════════════════════════════


-- ── 1. TABLE DES TRANSACTIONS ────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
  id          UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id     UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  type        TEXT NOT NULL CHECK (type IN ('income', 'expense')),
  amount      DECIMAL(12, 2) NOT NULL CHECK (amount > 0),
  date        DATE NOT NULL,
  category    TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  note        TEXT NOT NULL DEFAULT '',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour accélérer les requêtes par utilisateur et par date
CREATE INDEX IF NOT EXISTS idx_transactions_user_date
  ON transactions(user_id, date DESC);


-- ── 2. TABLE DES PARAMÈTRES UTILISATEUR ──────────────────
CREATE TABLE IF NOT EXISTS user_settings (
  user_id        UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  savings_pct    INTEGER NOT NULL DEFAULT 20,
  avg_months     INTEGER NOT NULL DEFAULT 3,
  fixed_expenses JSONB   NOT NULL DEFAULT '[]'::jsonb,
  cat_rules      JSONB   NOT NULL DEFAULT '[]'::jsonb,
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);


-- ── 3. SÉCURITÉ — Row Level Security (RLS) ───────────────
--  IMPORTANT : avec RLS activé, un utilisateur NE PEUT PAS
--  voir ou modifier les données d'un autre utilisateur,
--  même s'il connaît son ID.

ALTER TABLE transactions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Politique : chaque utilisateur ne voit que SES transactions
CREATE POLICY "transactions_own" ON transactions
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Politique : chaque utilisateur ne voit que SES paramètres
CREATE POLICY "settings_own" ON user_settings
  FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);


-- ── 4. VÉRIFICATION (optionnel) ──────────────────────────
-- Après avoir lancé le script, vérifiez que tout est OK :

SELECT table_name, row_security
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN ('transactions', 'user_settings');

-- Vous devriez voir :  transactions | YES  et  user_settings | YES

# Dev Session Brief — 2026-04-05

> Objectif : améliorer les capacités, l'autonomie et l'efficacité de Zé.
> À ouvrir dans Claude Code et travailler manuellement.

---

## A. OAuth Calendar Write Scope
**Problème :** Zé peut lire le calendrier mais pas écrire.
**Objectif :** Ajouter `calendar.events` scope au token Google OAuth.
**Fichiers concernés :**
- `~/clawd/credentials/google-tokens.json` (token actuel)
- `~/clawd/credentials/google-oauth-client.json` (client config)
- `~/clawd/venv-google/` (env Python avec google-auth)
**Direction :** Re-faire le flow OAuth avec le nouveau scope, sauvegarder le token rafraîchi. Tester création d'un event.

---

## B. Orchestration Agents — Améliorations
**Problème :** Subagents meurent avec SIGTERM, timeouts aléatoires, pas de reporting d'état fiable.
**Objectifs :**
- Comprendre pourquoi les execs longs se font SIGTERM (limite de temps OpenClaw ?)
- Améliorer la gestion des résultats partiels quand un agent timeout
- Réduire le polling inutile entre agents
- Memory compaction automatique entre sessions longues
**Fichiers à auditer :**
- `~/.openclaw/openclaw.json` — config agents, timeouts
- `~/clawd/scripts/` — scripts appelés par les crons
- Logs : `~/clawd/logs/`

---

## C. Accès Budget / Paiements
**Objectif :** Permettre à Zé de faire des achats sur Mercado Livre après validation de Théo.
**Direction à explorer :**
- API Mercado Livre (MercadoPago ?) — existe-t-elle pour des achats automatisés ?
- Workflow : Zé trouve l'item → envoie lien + prix → Théo valide → Zé achète
- Alternative : Zé prépare le panier, Théo checkout manuellement

---

## D. Monétisation
**Objectif :** Définir comment Zé peut contribuer à générer du revenu.
**Pistes à explorer :**
- Zé comme démo vivante de l'AI agency (showcase client)
- Pipeline job application comme service pour d'autres (SaaS ?)
- Agent d'automatisation facturable à des clients

---

## E. Heure Temps Réel
**Problème :** Zé infère l'heure depuis les timestamps des messages — imprécis.
**Objectif :** Accès fiable à l'heure actuelle à Rio (America/Sao_Paulo).
**Direction :** Script simple appelable par Zé via exec : `date --date='TZ="America/Sao_Paulo"'` ou endpoint worldtime API. Intégrer dans le prompt système ou via un outil léger.

---

## F. Duplication Réponses Telegram
**Problème :** Messages dupliqués observés — Zé répond deux fois.
**Objectif :** Identifier la cause et corriger.
**Pistes :**
- Crons qui se déclenchent en même temps que la session principale ?
- Double delivery dans OpenClaw config ?
- Logs à checker : `journalctl --user -u openclaw-gateway -n 100`
- Config : `~/.openclaw/openclaw.json` → channels.telegram

---

## G. Token Usage — Audit & Optimisation
**Problème :** Zé doit surveiller proactivement, pas Théo.
**Objectifs :**
- Comprendre le coût réel par session (tokens in/out, cache hit rate)
- Identifier les principales sources de consommation (bootstrap files, subagents, tools)
- Mettre en place un suivi automatique (log coût quotidien, alerte si dérive)
- Optimiser : quoi cacher, quoi compacter, quand spawner vs répondre directement
**Outils :** `ccusage` (si installé), `session_status` tool, logs OpenClaw

---

## H. Health & Habits Tracking System
**Objectif :** Système robuste pour suivre sommeil, nutrition, sport, habits.
**Ce qui existe déjà :**
- Habit tracker dans `Ob_Perso_Vault/Areas/Habit Tracker.md`
- Crons : gym nudge 6h20, bedtime 22h30, weekly life admin
- Fenêtre IF : 12h-18h
- Split : Upper/Lower 4x/semaine (Lun/Mar/Jeu/Ven)
**Ce qui manque :**
- Logging automatique des séances (Théo confirme → Zé log)
- Suivi sommeil (heure coucher/lever)
- Feedback loop hebdo (Zé analyse les données et fait des recommandations)
- Intégration avec daily note Obsidian

---

## Priorité suggérée
1. **F** — Duplication (bug visible immédiatement)
2. **E** — Heure temps réel (quick win, 10min)
3. **A** — Calendar write (débloque le time-blocking automatique)
4. **G** — Token audit (autonomie financière de Zé)
5. **B** — Orchestration (amélioration continue)
6. **H** — Health tracking system
7. **C/D** — Budget et monétisation (plus complexe, plus tard)

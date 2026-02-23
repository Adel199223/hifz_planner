# Localization Glossary

Single source of truth for app-facing terminology across `en`, `fr`, `pt`, and `ar`.

## Purpose

Use this glossary to keep terminology consistent across Reader, shell, and other screens.

## Governance Rules

1. If a term changes, update this glossary first.
2. Then update `lib/l10n/app_strings.dart`.
3. Then update screen usage and tests.
4. Avoid copying full term tables into other docs; link to this file instead.

## Reader Terminology (Quran.com overlap)

| Key | English | French | Portuguese | Arabic |
|---|---|---|---|---|
| `verse_by_verse` | Verse by Verse | Ayah par Ayah | Verso por verso | آية بآية |
| `reading` | Reading | Lecture | Lendo | القراءة |
| `surah` | Surah | Sourate | Surah | سورة |
| `verse` | Verse | Ayah | Versículo | آية |
| `juz` | Juz | Juz | Juz | جزء |
| `page` | Page | Page | Página | صفحة |
| `listen` | Listen | Écouter | Ouvir | استمع |
| `tajweed_colors` | Tajweed colors | Couleurs du Tajwid | Cores de Tajweed | ألوان التجويد |
| `tafsirs` | Tafsirs | Tafsirs | Tafsirs | تفاسير |
| `lessons` | Lessons | Leçons | Lições | فوائد |
| `reflections` | Reflections | Réflexions | Reflexões | تدبرات |
| `retry` | Retry | Réessayer | Tentar novamente | أعد المحاولة |
| `done` | Done | Fait | Feito | تم |

## Shell and App Navigation Terminology

| Key | English | French | Portuguese | Arabic |
|---|---|---|---|---|
| `reader` | Reader | Lecteur | Leitor | القارئ |
| `bookmarks` | Bookmarks | Signets | Favoritos | العلامات |
| `notes` | Notes | Notes | Notas | الملاحظات |
| `plan` | Plan | Plan | Plano | الخطة |
| `today` | Today | Aujourd'hui | Hoje | اليوم |
| `settings` | Settings | Paramètres | Configurações | الإعدادات |
| `about` | About | À propos | Sobre | حول |
| `read` | Read | Lire | Ler | اقرأ |
| `learn` | Learn | Apprendre | Aprender | تعلّم |
| `my_quran` | My Quran | Mon Coran | Meu Alcorão | قرآني |
| `quran_radio` | Quran Radio | Radio Coran | Rádio Alcorão | إذاعة القرآن |
| `reciters` | Reciters | Récitateurs | Recitadores | القرّاء |

## Known Intentional Duplicates

- `Surah` and `Juz` intentionally remain `Surah`/`Juz` in Portuguese and French usage for Quran-specific terminology.
- `Tafsirs` intentionally stays `Tafsirs` in English/French/Portuguese.

## Related Workflow

- `docs/assistant/workflows/LOCALIZATION_WORKFLOW.md`

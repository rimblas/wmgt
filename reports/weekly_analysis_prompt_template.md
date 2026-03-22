# Weekly Tournament Analysis Prompt Template

## Instructions for AI Assistant

Analyze the SQL results from `weekly_tournament_analysis.sql` for week **[WEEK_CODE]** and create a comprehensive tournament report following this structure:

### Required Report Sections:

#### 1. **Top 3 Podium** 🥇🥈🥉
- List winners with country, rank, points, and total score
- Brief comment on performance

#### 2. **Week Statistics** 📊
- Total players and countries
- Average scores and difficulty assessment
- Rank distribution insights
- Course preference patterns

#### 3. **🌟 PLAYER OF THE WEEK**
- Select someone **outside top 3** who had exceptional performance
- Focus on: rank overperformance, amateur standouts, or comeback stories
- Explain why they deserve recognition

#### 4. **Hidden Gems & Interesting Insights** 💎
Include analysis of:
- **Rank Upsets:** Players significantly outperforming their rank average
- **International Standouts:** Best performers from smaller countries
- **Course Mastery:** Best easy/hard course specialists
- **Perfect Balance:** Most consistent easy/hard performance
- **Participation Diversity:** Interesting country representation facts

#### 5. **Notable Achievements**
- Most consistent country performance
- Biggest surprises and disappointments
- Unique statistical achievements
- Fun facts and storylines

### Analysis Guidelines:
- **Focus on stories behind the numbers** - not just statistics
- **Highlight underdog performances** and unexpected results
- **Use emojis** to make it engaging and readable
- **Include specific player callouts** with their achievements
- **Compare performance vs rank expectations**
- **Look for interesting patterns** in country/rank performance
- **Always use wmg_players_v.player_name for names in the report and never use wmg_players.name**
- **Do NOT include @ tags** (Discord issue)

### Tone:
- Enthusiastic and engaging
- Celebrate achievements at all levels
- Focus on positive storylines
- Make statistics accessible and interesting

---

## Usage:
1. Run `weekly_tournament_analysis.sql` with desired week code
2. Use this prompt with the SQL results
3. Replace [WEEK_CODE] with actual week (e.g., S18W02)

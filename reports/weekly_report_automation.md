# Weekly Tournament Report Automation Guide

## **Level 1: Manual with Script (5 minutes/week)**

### Setup (One-time):
1. Save the SQL queries in `generate_weekly_report.sql`
2. Save the prompt template in `weekly_analysis_prompt_template.md`

### Weekly Process:
1. **Run the data collection:**
   ```
   Connect to wmgt database via MCP
   Run each query section manually, replacing 'S18W02' with current week
   ```

2. **Copy results and use this prompt:**
   ```
   Analyze this tournament data for week [WEEK_CODE] and create a comprehensive report following the template structure. Focus on finding the Player of the Week (outside top 3), interesting rank overperformances, country insights, and engaging storylines.
   Always use wmg_players_v.player_name for player names in the report. Do not use wmg_players.name. Do NOT include @ tags (Discord issue).

   [PASTE SQL RESULTS HERE]
   ```

## **Level 2: Kiro Hook Automation (1 click/week)**

### Create a Kiro Hook:
1. Open Command Palette → "Open Kiro Hook UI"
2. Create new hook: "Weekly Tournament Report"
3. Trigger: Manual button
4. Action: Run the analysis queries and generate report

### Hook Configuration:
```json
{
  "name": "Weekly Tournament Report Generator",
  "description": "Generate comprehensive weekly tournament analysis report",
  "trigger": "manual",
  "inputs": [
    {
      "name": "week_code",
      "type": "text",
      "label": "Week Code (e.g., S18W02)",
      "required": true
    }
  ]
}
```

## **Level 3: Fully Automated (Zero effort)**

### Option A: Scheduled Hook
- Hook triggers automatically when new tournament data appears
- Detects latest week automatically
- Generates report and saves to file
- Sends notification when complete

### Option B: Database Trigger
- Oracle trigger fires when tournament data is finalized
- Calls external API to generate report
- Emails report to stakeholders

## **Recommended Approach: Start with Level 1**

**Why Level 1 is perfect to start:**
- ✅ **5-minute setup** each week
- ✅ **Consistent results** every time
- ✅ **Easy to modify** queries or analysis
- ✅ **No complex setup** required
- ✅ **Learn what works** before automating

**Upgrade path:**
1. **Week 1-4:** Use Level 1 to refine the process
2. **Week 5+:** Create Kiro Hook for Level 2
3. **Later:** Full automation if needed

## **Quick Start for Next Week:**

### Step 1: Prepare the Prompt
```
Connect to wmgt database and analyze Week [WEEK_CODE]. 

Run these key queries and create a comprehensive tournament report:

1. Overall statistics (players, countries, scores, rank distribution)
2. Top 10 leaderboard 
3. Rank performance analysis
4. Overperformers (excluding top 3) - focus on players 10+ positions above their rank average
5. Country performance with best representatives
6. Special achievements (most balanced, best hard course, biggest gaps)

Create an engaging report with:
- Top 3 podium celebration
- Player of the Week (someone outside top 3 who overperformed significantly)
- Hidden gems and interesting insights
- Country and rank analysis
- Notable achievements and storylines
- Always source names from wmg_players_v.player_name, never wmg_players.name

Use emojis, focus on underdog stories, and make statistics engaging!
```

### Step 2: Weekly Execution
1. Replace [WEEK_CODE] with actual week (e.g., S18W03)
2. Paste prompt into chat
3. Get comprehensive report in 2-3 minutes
4. Save report for distribution

**This gives you 90% of the automation benefits with 10% of the complexity!**

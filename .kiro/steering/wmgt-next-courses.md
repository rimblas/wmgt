---
inclusion: manual
description: "Generate comprehensive course analysis report for upcoming Week {{week_code}} tournament courses, including difficulty rankings, records, hole analysis, and strategic insights"
---

Connect to "wmgt" database with sqlcl and analyze the upcoming courses for Week {{week_code}} tournament.

Generate a comprehensive course analysis report using the wmg_notification.tournament_courses_template as reference, including:

1. **Course Overview** - Basic info about each course (Easy and Hard modes)
2. **Risk/Difficulty Analysis** - Difficulty rankings compared to all courses
3. **Course Records** - Best scores ever achieved on these courses
4. **Historical Performance** - Top scores and notable achievements
5. **Hole Analysis** - Most challenging and easiest holes for each course
6. **Strategic Insights** - What players should expect and prepare for
7. **Unicorn Opportunities** - Special achievement possibilities (if eligible)

Analysis Guidelines:
- Use the email template format from apex/readable/application/shared_components/email_templates.yaml as reference
- Focus on actionable insights for players preparing for the tournament
- Include difficulty comparisons and strategic advice
- Use emojis and engaging formatting like the email templates
- Highlight what makes each course unique or challenging
- Provide context about when courses were last played

Key queries to run:
- Get tournament courses: SELECT ts.week, c.code, c.name, c.course_mode FROM wmg_tournament_sessions ts JOIN wmg_tournament_courses tc ON ts.id = tc.tournament_session_id JOIN wmg_courses c ON tc.course_id = c.id WHERE ts.week = '{{week_code}}'
- Course difficulty analysis from wmg_course_stats_v
- Historical records and top performances
- Hole-by-hole difficulty analysis
- Course release dates and last played information
- Unicorn eligibility and achievements

Format the output to match the style and structure of the TOURNAMENT_COURSES email template, making it informative and engaging for tournament participants!

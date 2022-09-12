players /insert 10
  account vc32 -- discord name
  name    vc60
courses /insert 2
    code vc5 /unique
    name /nn
    course mode /check E H
    rounds  /insert 10 -- Rounds by a player on a specific course
      player_id /fk players id
      round_played_on tsltz
      room_name
      s1 int -- hole 1 score
      s2 int -- hole 2 score
      s3 int -- hole 3 score
      s4 int -- hole 4 score
      s5 int -- hole 5 score
      s6 int -- hole 6 score
      s7 int -- hole 7 score
      s8 int -- hole 8 score
      s9 int -- hole 9 score
      s10 int -- hole 10 score
      s11 int -- hole 11 score
      s12 int -- hole 12 score
      s13 int -- hole 13 score
      s14 int -- hole 14 score
      s15 int -- hole 15 score
      s16 int -- hole 16 score
      s17 int -- hole 17 score
      s18 int -- hole 18 score
    course_strokes /insert 2 -- Par values for each hole on a course
      h1 int /nn -- hole 1 par value
      h2 int /nn -- hole 2 par value
      h3 int /nn -- hole 3 par value
      h4 int /nn -- hole 4 par value
      h5 int /nn -- hole 5 par value
      h6 int /nn -- hole 6 par value
      h7 int /nn -- hole 7 par value
      h8 int /nn -- hole 8 par value
      h9 int /nn -- hole 9 par value
      h10 int /nn -- hole 10 par value
      h11 int /nn -- hole 11 par value
      h12 int /nn -- hole 12 par value
      h13 int /nn -- hole 13 par value
      h14 int /nn -- hole 14 par value
      h15 int /nn -- hole 15 par value
      h16 int /nn -- hole 16 par value
      h17 int /nn -- hole 17 par value
      h18 int /nn -- hole 18 par value

view course_v courses course_strokes
view rounds_v players courses course_strokes rounds

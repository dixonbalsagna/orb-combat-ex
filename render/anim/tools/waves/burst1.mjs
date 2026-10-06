// PROVISIONAL (the held-X burst's set, docs/design/brawl-second-pass.md section 3, committed 13d5e7e0): "until 16 ticks a held X is a tap: one light, and then he sets himself for about 10 ticks. The set is the
// burst's tell, and the rival can answer in it." The stream follows at 18, 22, 26, 31, 37, 45 and 56 ticks from the press. A pose of 10 ticks or so (short of 12, so not a held pose), laid over the body between
// the first light and the stream's first blow by the `burst` press style's `set` row (data/anim/press_styles.json). It has to read as "more is coming": the body coiled and loaded forward, both hands up and ready,
// the eyes on him. Honest to h05 anyway: hands at shoulder height or lower, at least 16 apart, never together, never crossed, never at a hip, no light. Prefix bu. Parked (--waves): the layer plays only when
// a blow of the burst style has a stream blow 14 ticks or more behind it, and a live match names that style only when the sim does (C2a).
//   set_p   the Protagonist's: compact and forward, a low coiled guard, the palms open and ready at the chest, the head down on him
//   set_r   the rival's: a show of it, the weight back on the rear leg, the blade hands drawn back at the shoulders and open to view, the chin up
export const sequences = {
  set_p: { dur: 10, legal: ['hands_open_or_claw', 'not_at_hip'], phases: [
    { id: 'set', ticks: 10, sketch: { family: 'crouched', lean: 10, hips: [-2, -8, 0], spine: { lean: 8, twist: 4 }, head: { pitch: 6 }, hand_r: [22, 56, 12], pole_hand_r: [-6, -8, 10], hand_l: [20, 58, -12],
        foot_r: [-8, 2.5, 9], foot_l: [12, 2.5, -7], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL: the burst\'s set: a low coiled guard leaning on him, both open palms up and ready at the chest a shoulder width apart, the head down, the weight loaded on the front foot' },
  ] },
  set_r: { dur: 10, legal: ['hands_open_or_claw', 'not_at_hip'], phases: [
    { id: 'set', ticks: 10, sketch: { family: 'crouched', lean: -4, hips: [-6, -6, 0], spine: { lean: -2, twist: -10 }, head: { pitch: -6 }, hand_r: [2, 62, 18], pole_hand_r: [-10, 4, 12], hand_l: [14, 60, -14],
        foot_r: [-14, 2.5, 10], foot_l: [10, 2.5, -8], hands: { r: 'open', l: 'open' } },
      orig: 'PROVISIONAL: the burst\'s set, his way: the weight sunk on the rear leg, the blade hands drawn back to the shoulders and open to view, the chin up: a show that more is coming' },
  ] },
};

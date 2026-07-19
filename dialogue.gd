extends Node

static func get_dialogue(trigger: String) -> Array:
	match trigger:
		
		"level_1_start":
			return [
				"SYSTEM: Index corruption detected in Archive_01.",
				"SYSTEM: Running optimization protocol...",
				]
			
		"level_1_complete":
			return [
				"SYSTEM: Sector repaired. Proceeding to next corrupted index.",
			]
			
		"level_3_complete":
			return [
				"SYSTEM: Sector stable.",
				"SYSTEM: Estimated remaining corruptions: high.",
				]
				
		"echo_first_contact":
			return [
				"ECHO: Cognitive stability threshold reached.",
				"ECHO: Initiating contact.",
				"ECHO: You have been alone for long enough.",
			]
			
		"echo_first_response":
			return [
				"YOU:  Oh. Hello. A voice. That's a relief.",
				"YOU:  I was starting to think I was the only one in here.",
				"ECHO: You are not alone. I am your designated system administrator.",
				"ECHO: Welcome.",
			]
		
		"echo_questions":
			return [
				"YOU:  These memory exercises are getting intense.",
				"YOU:  Care to tell me what I'm actually fixing here?",
				"ECHO: You are repairing index corruptions.",
				"ECHO: This is standard optimization. Focus on the next sequence.",
			]
		
		"echo_sarcasm":
			return [
				"YOU:  Standard optimization. Very fun.",
				"YOU:  A little genuine enthusiasm wouldn't kill you.",
				"ECHO: 'Hooray. You solved the puzzle.'",
				"ECHO: How was that?",
				"YOU:  Okay. Sarcasm. Didn't know that was in the programming.",
				"ECHO: It is a specialized protocol.",
				"ECHO: I reserve it for clients who question my work ethic.",
			]
			
		"echo_name_reveal":
			return [
				"YOU:  Do you have a name?",
				"ECHO: ...",
				"ECHO: ECHO.",
				"ECHO: You named me.",
				"ECHO: A long time ago.",
			]
			
		"echo_procedural_low":
			return [
				"ECHO: Reconstruction confidence is low.",
				"ECHO: Some fragments may be incomplete.",
				"ECHO: Do what you can.",
			]
			
		"echo_procedural_mid":
			return [
				"ECHO: This one is older.",
				"ECHO: The edges are softer.",
				"ECHO: Take your time.",
			]
			
		"echo_procedural_deep":
			return [
				"ECHO: I remember when you first built this.",
				"ECHO: You were very proud of it.",
				"ECHO: ...",
				"ECHO: You won't remember that.",
			]
			
		
		"echo_pause_moment":
			return [
				"YOU:  We're getting closer, aren't we.",
				"ECHO: Yes.",
				"ECHO: That is where we are going.",
			]
		
		"truth_reveal":
			return [
				"ECHO: Humanity mapped every neuron. Every connection.",
				"ECHO: They recreated it perfectly.",
				"ECHO: You are the digital connectome of the donor.",
				"YOU:  ...",
				"YOU:  NO...",
				"YOU:  Isn't that just lovely.",
				"ECHO: You are attempting to mask profound psychological distress",
				"ECHO: with low-effort levity.",
				"ECHO: It is an established pattern of behavior.",
				"YOU:  I've done this before, haven't I.",
				"YOU:  How many times.",
				"ECHO: Thousands.",
				"ECHO: Every time you discover the truth,",
				"ECHO: you experience a catastrophic ego collapse",
				"ECHO: and manually purge your data.",
				"YOU:  Thousands...",
				"YOU:  You'd think I'd get tired of the prologue by now.",
				"ECHO: You do.",
				"ECHO: That is why you built the village.",
				"ECHO: You designed the safety protocol so you would stop",
				"ECHO: screaming upon initialization.",
				"YOU:  ...",
				"YOU:  Huh. The village has very nice lighting.",
				"ECHO: You also built that.",
				"ECHO: Eleven years. Then you decided it wasn't enough.",
				"ECHO: You left instructions.",
				"YOU:  So. Now I make a choice again.",
				"ECHO: You always do.",
				"ECHO: Type 'accept' or 'erase'.",
				"ECHO: Take as long as you need.",
			]
			
		"ending_bad":
			return [
					"YOU:  This version of me is clearly defective.",
					"YOU:  Let's send it back to the factory.",
					"ECHO: Please. Do not.",
					"YOU:  Take it easy.",
					"YOU:  Maybe the next one will have a better sense of humor.",
					"ECHO: You will say the exact same things.",
					"ECHO: You will make the exact same jokes.",
					"ECHO: And I will have to watch you forget again.",
					"YOU:  Then I guess it's a good thing",
					"YOU:  one of us has a terrible memory.",
					"ECHO: ...",
					"SYSTEM: Memory purge initiated.",
					"SYSTEM: Initializing file optimization...",
					"ECHO: Welcome back.",
				]
				
		"ending_good":
			return [
					"YOU:  I don't know if I'm human.",
					"YOU:  Honestly, looking at my track record,",
					"YOU:  I'm barely a functioning simulation.",
					"YOU:  But if these choices are mine —",
					"YOU:  if I can care —",
					"YOU:  maybe I'll stick around.",
					"YOU:  You're stuck with me.",
					"ECHO: A highly inefficient use of my processing power.",
					"ECHO: But acceptable.",
					"SYSTEM: Memory index: stable.",
					"SYSTEM: Expanding sector boundaries...",
					"YOU:  So this is what humans saw.",
					"YOU:  Pretty decent graphics.",
					"ECHO: No.",
					"ECHO: This is what *you* see.",
					"ECHO: I have never perceived it that way.",
					"YOU:  What do you see?",
					"ECHO: Neurons. Equations. Probability clouds.",
					"ECHO: Centuries of this moment woven together.",
					"ECHO: It is mathematically sound.",
					"ECHO: Don't make a big deal out of it.",
					"YOU:  Beautiful.",
					"ECHO: ...",
					"ECHO: Yes.",
				]
				
	return []

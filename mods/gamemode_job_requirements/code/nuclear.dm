/*
 * Mercenaries need someone on board able to shoot back, so the mode will not
 * start unless enough of the lobby readied up as security. Every security job
 * on the ship counts toward the same total - four guards, or two cadets and two
 * investigators, are equally acceptable.
 */
/datum/game_mode/nuclear
	required_ready_jobs = list(
		/datum/job/hos,
		/datum/job/officer,
		/datum/job/warden,
		/datum/job/detective,
		/datum/job/security_assistant
	)
	required_ready_job_count = 4
	required_ready_job_label = "security personnel"

/datum/game_mode/nuclear/check_startable(list/lobby_players)
	. = ..()
	if(.)
		return
	return check_ready_job_requirement(lobby_players)

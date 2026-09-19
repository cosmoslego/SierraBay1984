/*
 * GAMEMODE_JOB_REQUIREMENTS
 *
 * Lets a game mode demand that some number of lobby players have readied up as
 * one of a set of jobs before the mode is allowed to start. Counting only cares
 * about the job a player readied *as*, not about how many slots that job has.
 *
 * A mode opts in by filling the three vars below and chaining
 * check_ready_job_requirement() into its check_startable() - see nuclear.dm.
 * Modes that leave the vars alone are completely unaffected.
 */

/datum/game_mode
	/// Job types whose readied players count toward `required_ready_job_count`. Null or empty disables the requirement entirely.
	var/list/required_ready_jobs
	/// How many ready players across `required_ready_jobs` the mode needs before it may start.
	var/required_ready_job_count = 0
	/// Plural noun for the rejection message, as in "2/4 ready security personnel".
	var/required_ready_job_label = "players"

/*
 * Falsy if the requirement is met (or does not apply), otherwise a status
 * message, matching the contract of /datum/game_mode/proc/check_startable().
 */
/datum/game_mode/proc/check_ready_job_requirement(list/lobby_players)
	if(!length(required_ready_jobs) || required_ready_job_count <= 0)
		return
	// Players who deliberately voted this mode in get what they asked for, even
	// if nobody signed up to oppose them.
	if(was_voted_in())
		return
	var/ready = count_ready_for_jobs(SSticker.ready_players(lobby_players), required_ready_jobs)
	if(ready < required_ready_job_count)
		return "[ready]/[required_ready_job_count] ready [required_ready_job_label]"

/// TRUE if players picked this mode in the pre-round gamemode vote.
/datum/game_mode/proc/was_voted_in()
	if(SSticker.bypass_gamemode_vote)
		return FALSE
	// SSticker.choose_gamemode() takes the first entry as the winner, and leaves
	// the list empty when a vote finished without one.
	var/list/results = SSticker.gamemode_vote_results
	if(!length(results))
		return FALSE
	return results[1] == config_tag

/*
 * How many of `ready_players` readied up as one of `job_types`.
 *
 * Matches on job title rather than type because that is what a readied job is
 * stored as. Alt titles need no handling here - preferences keep job_high as
 * the job's base title and stash the chosen alt title separately, so someone
 * readied as "Junior Guard" already counts as a /datum/job/officer.
 *
 * Job types absent from the running map simply contribute nothing.
 */
/datum/game_mode/proc/count_ready_for_jobs(list/ready_players, list/job_types)
	var/list/titles = list()
	for(var/job_type in job_types)
		var/datum/job/job = SSjobs.get_by_path(job_type)
		if(job)
			titles |= job.title
	if(!length(titles))
		return 0

	var/count = 0
	for(var/mob/new_player/player in ready_players)
		if(player.get_ready_job_title() in titles)
			count++
	return count

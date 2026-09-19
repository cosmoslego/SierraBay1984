/*
 * GAMEMODE_JOB_REQUIREMENTS
 *
 * Lets a game mode demand that some number of lobby players have readied up as
 * a job from a given department before the mode is allowed to start. Counting
 * only cares about the job a player readied *as*, not about how many slots that
 * job has.
 *
 * Departments are matched by flag rather than by a list of job types on purpose.
 * Job types are per-map - /datum/job/security_assistant, for instance, exists
 * only on Sierra - so a list of them would fail to compile on every other map.
 * Flags also mean a map that adds a security job gets it counted for free.
 *
 * A mode opts in by filling the three vars below and chaining
 * check_ready_job_requirement() into its check_startable() - see nuclear.dm.
 * Modes that leave the vars alone are completely unaffected.
 */

/datum/game_mode
	/// Department flags whose readied players count toward `required_ready_job_count`. 0 disables the requirement entirely.
	var/required_ready_job_departments = 0
	/// How many ready players from `required_ready_job_departments` the mode needs before it may start.
	var/required_ready_job_count = 0
	/// Plural noun for the rejection message, as in "2/4 ready security personnel".
	var/required_ready_job_label = "players"

/*
 * Falsy if the requirement is met (or does not apply), otherwise a status
 * message, matching the contract of /datum/game_mode/proc/check_startable().
 */
/datum/game_mode/proc/check_ready_job_requirement(list/lobby_players)
	if(!required_ready_job_departments || required_ready_job_count <= 0)
		return
	// Players who deliberately voted this mode in get what they asked for, even
	// if nobody signed up to oppose them.
	if(was_voted_in())
		return
	var/ready = count_ready_for_departments(SSticker.ready_players(lobby_players), required_ready_job_departments)
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

/// Every job title on the running map belonging to any of `department_flags`.
/datum/game_mode/proc/get_department_job_titles(department_flags)
	var/list/titles = list()
	if(!department_flags)
		return titles
	for(var/title in SSjobs.titles_to_datums)
		var/datum/job/job = SSjobs.titles_to_datums[title]
		if(job && (job.department_flag & department_flags))
			titles |= job.title
	return titles

/*
 * How many of `ready_players` readied up as a job from `department_flags`.
 *
 * Matches on job title because that is what a readied job is stored as. Alt
 * titles need no handling here - preferences keep job_high as the job's base
 * title and stash the chosen alt title separately, so someone readied as
 * "Junior Guard" already counts as a Security Guard.
 */
/datum/game_mode/proc/count_ready_for_departments(list/ready_players, department_flags)
	var/list/titles = get_department_job_titles(department_flags)
	if(!length(titles))
		return 0

	var/count = 0
	for(var/mob/new_player/player in ready_players)
		if(player.get_ready_job_title() in titles)
			count++
	return count

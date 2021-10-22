module ProcessHelper

  def legislation_process_back_link(process)
    ret = legislation_processes_path
    if process.process_type == 2
      ret = works_path
    elsif process.process_type == 3
      ret = chances_path
    elsif process.process_type == 5
      ret = chances_path        
    elsif process.process_type == 4
      ret = works_path 
    elsif process.process_type == 1
      ret = processes_proposals_path   
    end
    ret
  end


  def legislation_process_edit_link(process)
    ret = ''
    if process.process_type == 2
      ret = edit_admin_legislation_process_work_path(@process)
    elsif process.process_type == 3
      ret = edit_admin_legislation_process_chance_path(@process)
    elsif process.process_type == 5
      ret = edit_admin_legislation_process_chance_path(@process)
    elsif process.process_type == 1
      ret = edit_admin_legislation_process_processes_proposal_path(@process)
    end
    ret
  end


  def author_of_process?(process)
    author_of?(process, current_user)
  end

  def legislation_process_current_editable?(process)
    current_user && process.editable_by?(current_user)
  end

  def print_correct_date(date)

    if date.year == 9999
      
      "-"
    else
      I18n.localize(date.to_date)
    end
  end


  def check_process_fase(process)
    process.debate_phase.enabled? || process.proposals_phase.enabled? || process.draft_publication.enabled? || process.allegations_phase.enabled? ||process.result_publication.enabled?    
  end
end

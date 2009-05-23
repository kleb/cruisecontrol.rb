require File.expand_path(File.dirname(__FILE__) + '/../test_helper')

class SuccessfulBuildTriggerTest < Test::Unit::TestCase
  include FileSandbox
  include BuildFactory

  def setup
    setup_sandbox
    @triggered_project = create_project('triggered_project')
    @triggering_project = create_project('triggering_project')
    Project.stubs(:new).with('triggering_project').returns(@triggering_project)
    @trigger = SuccessfulBuildTrigger.new(@triggered_project, @triggering_project.name)
  end

  def teardown
    teardown_sandbox
  end

  def test_triggering_project_name_available
    assert_equal 'triggering_project', @trigger.triggering_project_name
  end

  def test_find_no_successful_builds_of_unbuilt_triggering_project
    assert_equal :none, @trigger.last_successful_build
  end

  def test_find_successful_build_of_triggering_project
    create_build @triggering_project, 1
    assert_equal "1", @trigger.last_successful_build.label
  end

  def test_find_last_successful_build_of_previously_successful_triggering_project
    create_build @triggering_project, 1
    trigger = SuccessfulBuildTrigger.new(@triggered_project, @triggering_project.name)
    assert_equal "1", trigger.last_successful_build.label
  end

  def test_build_not_necessary_if_triggering_project_has_no_builds_yet
    assert !@trigger.build_necessary?(reasons = [])
  end

  def test_build_necessary_after_triggering_build_is_successful
    create_build @triggering_project, 1
    assert @trigger.build_necessary?(reasons = [])
  end

  def test_build_not_necessary_when_asked_a_second_time_when_nothing_else_has_changed
    create_build @triggering_project, 1
    @trigger.build_necessary?(reasons = [])
    assert !@trigger.build_necessary?(reasons = [])
  end

  def test_triggering_build_sets_trigger_last_successful_build_label
    create_build @triggering_project, 1
    assert_equal '1', @trigger.last_successful_build.label
  end

  def test_repeated_triggering_builds_set_trigger_last_successful_build_label
    create_build @triggering_project, 1
    create_build @triggering_project, 1.1
    assert_equal '1.1', @trigger.last_successful_build.label
  end

  private

  def create_build(project, label, state = :succeed!)
    project.create_build(label).build_status.send(state, 0)
  end
end

require 'spec_helper'
require_relative '../../../lib/quiz_regrading'

describe QuizRegrader do

  before { Timecop.freeze(Time.local(2013)) }
  after { Timecop.return }

  let(:questions) do
    1.upto(4).map do |i|
      stub(:id => i, :question_data => { :id => i, :regrade_option => 'full_credit'})
    end
  end

  let(:submissions) do
    1.upto(4).map {|i| stub(:id => i, :completed? => true) }
  end

  let(:current_quiz_question_regrades) do
    1.upto(4).map { |i| stub(:quiz_question_id => i, :regrade_option => 'full_credit') }
  end

  let(:quiz) { stub(:quiz_questions => questions,
                    :id => 1,
                    :version_number => 1,
                    :current_quiz_question_regrades => current_quiz_question_regrades,
                    :quiz_submissions => submissions) }

  let(:quiz_regrade) { stub(:id => 1, :quiz => quiz) }

  before do
    quiz.stubs(:current_regrade).returns quiz_regrade
    QuizQuestion.stubs(:where).with(quiz_id: quiz.id).returns questions
    QuizSubmission.stubs(:where).with(quiz_id: quiz.id).returns submissions
  end

  let(:quiz_regrader) { QuizRegrader.new(quiz) }

  describe '#initialize' do
    it 'saves the quiz passed' do
      quiz_regrader.quiz.should == quiz
    end

    it 'takes an optional submissions argument' do
      submissions = []
      QuizRegrader.new(quiz,submissions).submissions.should == submissions
    end
  end

  describe "#submissions" do
    it 'should skip submissions that are in progress' do
      questions << stub(:id => 5, :question_data => {:regrade_option => 'no_regrade'})

      uncompleted_submission = stub(:id => 5, :completed? => false)
      submissions << uncompleted_submission

      quiz_regrader.submissions.length.should == 4
      quiz_regrader.submissions.detect {|s| s.id == 5 }.should be_nil
    end
  end

  describe '#regrade!' do
    it 'creates a QuizRegrader::Submission for each submission and regrades them' do
      questions << stub(:id => 5, :question_data => {:regrade_option => 'no_regrade'})
      questions << stub(:id => 6, :question_data => {} )

      QuizRegradeRun.expects(:perform).with(quiz_regrade)
      QuizRegrader::Submission.any_instance.stubs(:regrade!)

      quiz_regrader.regrade!
    end
  end
end

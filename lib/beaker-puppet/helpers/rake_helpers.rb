module Beaker
  module DSL
    module Helpers
      # Methods that help you interact with rake during ci setup
      module RakeHelpers
        class << self
          def load_tasks(beaker_root = File.expand_path("#{__dir__}/../../.."))
            task_dir = File.join(beaker_root, 'tasks')
            tasks = [
              'ci.rake'
            ]

            tasks.each do |task|
              load File.join(task_dir, task)
            end
          end
        end
      end
    end
  end
end

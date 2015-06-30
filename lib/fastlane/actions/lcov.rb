module Fastlane
  module Actions
    class LcovAction < Action

      def self.is_supported?(platform)
        true
      end

      def self.run(options)
        unless Helper.test?
          raise 'lcov not installed, please install using `brew install lcov`'.red if `which lcov`.length == 0
        end
        handle_exceptions(options)
        gen_cov(options)
      end

      def self.description
        "Generates coverage data using lcov"
      end

      def self.available_options
        [

          FastlaneCore::ConfigItem.new(key: :project_name,
                                       env_name: "PROJECT_NAME",
                                       description: "Name of the project"),

          FastlaneCore::ConfigItem.new(key: :scheme,
                                       env_name: "SCHEME",
                                       description: "Scheme of the project"),

          FastlaneCore::ConfigItem.new(key: :output_dir,
                                       env_name: "OUTPUT_DIR",
                                       description: "The output directory that coverage data will be stored. If not passed will use coverage_reports as default value",
                                       optional: true,
                                       is_string: true,
                                       default_value: "coverage_reports")


        ]
      end

      def self.author
        "thiagolioy"
      end

      private
        def self.handle_exceptions(options)
            unless (options[:project_name] rescue nil)
              Helper.log.fatal "Please add 'ENV[\"PROJECT_NAME\"] = \"a_valid_project_name\"' to your Fastfile's `before_all` section.".red
              raise 'No PROJECT_NAME given.'.red
            end

            unless (options[:scheme] rescue nil)
              Helper.log.fatal "Please add 'ENV[\"SCHEME\"] = \"a_valid_scheme\"' to your Fastfile's `before_all` section.".red
              raise 'No SCHEME given.'.red
            end
        end

        def self.gen_cov(options)
          tmp_cov_file = "/tmp/coverage.info"
          output_dir = options[:output_dir]
          derived_data_path = derived_data_dir(options)

          system("lcov --capture --directory \"#{derived_data_path}\" --output-file #{tmp_cov_file}")
          system(gen_lcov_cmd(tmp_cov_file))
          system("genhtml #{tmp_cov_file} --output-directory #{output_dir}")
        end

        def self.gen_lcov_cmd(cov_file)
          cmd = "lcov "
          exclude_dirs.each do |e|
            cmd << "--remove #{cov_file} \"#{e}\" "
          end
          cmd << "--output #{cov_file} "
        end

        def self.derived_data_dir(options)
           pn = options[:project_name]
           sc = options[:scheme]

           initial_path = "#{Dir.home}/Library/Developer/Xcode/DerivedData/"
           end_path = "/Build/Intermediates/#{pn}.build/Debug-iphonesimulator/#{sc}.build/Objects-normal/i386/"

           match = find_project_dir(pn,initial_path)

           "#{initial_path}#{match}#{end_path}"
        end

        def self.find_project_dir(project_name,path)
          `ls -t #{path}| grep #{project_name} | head -1`.to_s.gsub(/\n/, "")
        end

        def self.exclude_dirs
          ["/Applications/*","/Frameworks/*"]
        end

    end
  end
end

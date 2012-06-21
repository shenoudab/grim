module Grim
  class ImageMagickProcessor

    # ghostscript prints out a warning, this regex matches it
    WarningRegex = /\*\*\*\*.*\n/

    def initialize(options={})
      @imagemagick_path = options[:imagemagick_path] || 'convert'
      @ghostscript_path = options[:ghostscript_path]
      @original_path        = ENV['PATH']
    end

    def count(path)
      command = ["-dNODISPLAY", "-q",
        "-sFile=#{Shellwords.shellescape(path)}",
        File.expand_path('../../../lib/pdf_info.ps', __FILE__)]
      @ghostscript_path ? command.unshift(@ghostscript_path) : command.unshift('gs')
      result = `#{command.join(' ')}`
      result.gsub(WarningRegex, '').to_i
    end

    def save(pdf, index, path, options, processor_options)
      width   = options.fetch(:width,   Grim::WIDTH)
      height  = options.fetch(:height,  Grim::HEIGHT)
      density = options.fetch(:density, Grim::DENSITY)
      quality = options.fetch(:quality, Grim::QUALITY)
      resize  = options.fetch(:resize,  Grim::RESIZE)
      command = [@imagemagick_path, "-flatten", "-antialias", "-render",
        "-quality", quality.to_s,
        "-interlace", "none", "-density", density.to_s,
        "#{Shellwords.shellescape(pdf.path)}[#{index}]", path]

      if resize
        command.insert(2, "-resize")
        if height == 0
            command.insert(3, width.to_s)
	      else
	          command.insert(3, "#{width.to_s}x#{height.to_s}!")
	      end
      end

      if processor_options.any?
        processor_options.each_pair do |key, value|
          command.insert(10, "-#{key.to_s}")
          command.insert(11, value.is_a?(String) ? "#{value}" : value )
        end
      end

      command.unshift("PATH=#{File.dirname(@ghostscript_path)}:#{ENV['PATH']}") if @ghostscript_path

      result = `#{command.join(' ')}`

      $? == 0 || raise(UnprocessablePage, result)
    end
  end
end
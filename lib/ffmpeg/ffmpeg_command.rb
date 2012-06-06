module FFMpegCommand
  extend self

  @commands = []

  def <<(cmd)
    @commands << cmd
  end

  def add_at(cmd, pos)
    @commands.insert(pos, cmd)
  end

  def clear
    @commands.clear
  end

  def command(prefix="")
    output = ''
    @commands.each { |command| output += " #{command}" }
    return output
  end
end


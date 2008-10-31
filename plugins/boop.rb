# TODO
#
# - convert/filter out HTML entities like &quot;
# - do the right thing when a paste occurs (remove the 'view paste' but keep the content)

class Boop < CampfireBot::Plugin
  
  # Markov chain implementation courtesy of http://blog.segment7.net/articles/2006/02/25/markov-chain
  
  on_message /.*/,                :listen
  on_command 'speak',             :random_chatter
  on_command 'prime_chains',      :load_transcripts
  
  on_command 'test',              :debug
  
  def initialize
    @phrases    = Hash.new { |hash, key| hash[key] = [] } # phrase => next-word possibilities
    @word_count = 0
  end
  
  def debug
    p @phrases
  end
  
  def listen(msg)
    add_line(msg[:message])
  end
  
  def random_chatter(msg)
    puts "random_chatter"
    speak(generate_line)
  end
  
  def focused_chatter(msg)
    
  end
  
  def load_transcripts(msg)
    speak("Filling my brain with transcripts...")
    
    puts "available transcripts - #{bot.room.available_transcripts.to_yaml}"
    
    bot.room.available_transcripts.to_a.each do |date|
      puts "loading transcript #{date}"
      
      transcript = bot.room.transcript(date)
      
      transcript.each do |message|
        puts "message: #{message[:message]}"
        
        filtered_text = strip_message(message)
        add_line(filtered_text.gsub(/([^\.])$/, '\1.')) unless filtered_text.blank?
        
        puts "ACCEPTED: " + filtered_text.gsub(/([^\.])$/, '\1.') unless filtered_text.blank?
      end
    end
    
    speak("Primed!")
  end
  
  private
    
  def add_line(line)
    words        = line.scan(/\S+/)
    @word_count += words.length
    
    words.each_with_index do |word, index|
      phrase = words[index, phrase_length]             # current phrase
      @phrases[phrase] << words[index + phrase_length] # next possibility
    end
  end
  
  def generate_line
    # our seed phrase
    # phrase = words[0, phrase_length]
    phrase = [random_word]

    output = []

    @word_count.times do
      # grab all possibilities for our state
      options = @phrases[phrase]

      # add the first word to our output and discard
      output << phrase.shift

      # select at random and add it to our phrase
      phrase.push(options.rand)

      # the last phrase of the input text will map to an empty array of
      # possibilities so exit cleanly.
      break if phrase.compact.empty? # all out of words
    end

    # return our output
    output.join(' ')
  end
    
  def random_word
    @phrases.keys.rand.first
  end
  
  # amount of state (order-k)
  def phrase_length
    1
  end
  
  def strip_message(msg)
    str = msg[:message].to_s
    
    return '' if str.blank?
    
    # return nothing if the line is a bot command
    return '' if str[0..0] == '!' || str =~ Regexp.new("^#{bot.config['nickname']},", Regexp::IGNORECASE)
    
    # and get rid of the messages that are generated by the campfire system itself
    return '' if str =~ /has (entered|left) the room/
    return '' if str =~ /^View paste/
    
    # also get rid of the stuff spoken by the bot
    return '' if msg[:person] == bot.config['nickname']
    
    # now strip out all image tags completely
    str.gsub!(/<img\s.*?\/>/, '')
    
    # and now strip out all other html tags, leaving their contents intact
    str.gsub(/<\/?[^>]*>/, "")
  end
  
end
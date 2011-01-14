require 'dropbox'

unless File.exist?('keys.json')
  raise "Create a keys.json file with your Dropbox API credentials. See keys.json.example to get started."
end

settings = JSON.parse(File.read('keys.json'))

session = Dropbox::Session.new(settings['key'], settings['secret'])
session.mode = :sandbox
puts "Visit #{session.authorize_url} to log in to Dropbox. Hit enter when you have done this."
gets
session.authorize

# upload a file
puts "Uploading ChangeLog..."
session.upload 'ChangeLog', '/'
uploaded_file = session.file('ChangeLog')
puts "Done! #{uploaded_file.inspect}"
puts uploaded_file.metadata.size

puts "Deleting file..."
uploaded_file.delete
puts "Done!"

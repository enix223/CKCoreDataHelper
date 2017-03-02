Pod::Spec.new do |s|

  s.name         = "CKCoreDataHelper"
  s.version      = "0.0.2"
  s.summary      = "An implementation of CoreData Helper. Including data import from XML/JSON"

  s.description  = <<-DESC
  CKCoreDataHelper is an implementation of CoreData Helper origin from <<Learning Core Data for iOS>>. 
  This library also include a data importer supporting both XML and JSON formats.
                   DESC

  s.homepage     = "https://github.com/enix223/CKCoreDataHelper"

  s.license      = "MIT"
  s.author       = { "Enix Yu" => "enix223@163.com" }

  s.platform     = :ios
  s.platform     = :ios, "7.0"

  s.requires_arc   = true
  s.source       = { :git => "https://github.com/enix223/CKCoreDataHelper.git", :tag => "#{s.version}" }

  s.source_files  = "CKCoreDataHelper", "CKCoreDataHelper/**/*.{h,m}"
  s.exclude_files = "CKCoreDataHelper/Exclude"

  
  s.framework  = "CoreData"

end

module Site
  class LoadFromLocal
    include Interactor::Organizer

    organize [
         Site::LoadDataFromDirectory,
         Site::SaveSiteToIronGrid,
         Site::WriteRegistrationsToStretched,
         Site::WriteScriptsToStretched,
         Site::WriteLoadablesToIronGrid
     ]
  end
end
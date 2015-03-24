module Site
  class UpdateFromLocal
    include Interactor::Organizer

    organize [
         Site::LoadDataFromDirectory,
         Site::UpdateSiteInIronGrid,
         Site::WriteRegistrationsToStretched,
         Site::WriteScriptsToStretched
     ]
  end
end
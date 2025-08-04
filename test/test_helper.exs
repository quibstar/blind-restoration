ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(BlindShop.Repo, :manual)

# Start ExVCR
ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")

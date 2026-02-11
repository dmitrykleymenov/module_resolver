{:ok, _} = Application.ensure_all_started(:mox)

Mox.defmock(StorageMock, for: ModuleResolver.Storage)

ExUnit.start()

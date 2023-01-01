defmodule KV.RegistryTest do
    use ExUnit.Case, async: true

    setup context do
        _ = start_supervised!({KV.Registry, name: context.test})
        %{registry: context.test}
    end

    test "spawn buckets", %{registry: registry} do
        assert KV.Registry.lookup(registry, "shopping") == :error

        KV.Registry.create(registry, "shopping")
        assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

        KV.Bucket.put(bucket, "milk", 1)
        assert KV.Bucket.get(bucket, "milk") == 1
    end

    test "removes bucket on exit", %{registry: registry} do
        # This test is registry GenServer know if a Agent Backet have crashed for normal reason
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
        Agent.stop(bucket, :normal)

        _ = KV.Registry.create(registry, "bogus")
        assert KV.Registry.lookup(registry, "shopping") == :error
    end
    
    test "removes bucket on crash", %{registry: registry} do
        # This test is to show is a registry GenServer wont crash if a Backet Agent creashed 
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
        
        Agent.stop(bucket, :shutdown)

        # Create another bucket for guarantee :DOWN message was processed
        _ = KV.Registry.create(registry, "bogus") 
        assert KV.Registry.lookup(registry, "shopping") == :error
    end

    test "bucket can crash at any time", %{registry: registry} do
        KV.Registry.create(registry, "shopping")
        {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

        # Simulate a bucket crash by explicitly and synchronously shutting it down
        Agent.stop(bucket, :shutdown)

        # Now trying to call the dead process causes a :noproc exit
        catch_exit KV.Bucket.put(bucket, "milk", 3)
    end
    
end
defmodule KV.BucketTest do
    use ExUnit.Case, async: true

    setup do
        bucket = start_supervised!(KV.Bucket)
        #{:ok, bucket} = KV.Bucket.start_link([])
        %{bucket: bucket}
    end

    test "store a value by key", %{bucket: bucket} do
        
        assert KV.Bucket.get(bucket, "milk") == nil

        KV.Bucket.put(bucket, "milk", 3)
        assert KV.Bucket.get(bucket, "milk") == 3
    end

    test "delete a value by key", %{bucket: bucket} do
        KV.Bucket.put(bucket, "milk", 3)
        assert KV.Bucket.get(bucket, "milk") == 3

        KV.Bucket.delete(bucket, "milk")
        assert KV.Bucket.get(bucket, "milk") == nil
    end

    test "are temporary workers" do
        # Child_spec is a function of return how initialize a server like Agent or GenServer
        # And return a map of do it
        assert Supervisor.child_spec(KV.Bucket, []).restart == :temporary 
    end



end
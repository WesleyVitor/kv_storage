defmodule KV.Bucket do
    use Agent, restart: :temporary

    @spec start_link([term]) :: {:ok, pid()} | {:error, String.t}
    def start_link(_list) do
        Agent.start_link(fn -> %{} end)
    end

    @spec get(pid(), String.t) :: term
    def get(bucket, key) do
        Agent.get(bucket, &Map.get(&1, key))
    end

    @spec put(pid(), String.t, term) :: none
    def put(bucket, key, value) do
        Agent.update(bucket, &Map.put(&1, key, value))
    end

    @spec delete(pid(), String.t) :: none
    def delete(bucket, key) do
        Agent.get_and_update(bucket, &Map.pop(&1, key))
    end

    
end
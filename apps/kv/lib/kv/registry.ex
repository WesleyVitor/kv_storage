defmodule KV.Registry do
    use GenServer

    # Client API

    @doc """
        Start the registry
    """
    def start_link(opts) do
        server = Keyword.fetch!(opts, :name)
        GenServer.start_link(__MODULE__, server, opts)
    end

    @doc """
    Looks up the bucket pid for `name` stored in `server`.

    Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
    """
    def lookup(server, name) do
        case :ets.lookup(server, name) do
            [{^name, pid}] -> {:ok, pid}
            [] -> :error
        end
    end

    @doc """
    Ensures there is a bucket associated with the given `name` in `server`.
    """
    def create(server, name) do
        GenServer.call(server, {:create, name})
    end



    #Server API

    @impl true
    def init(table) do
        names = :ets.new(table, [:named_table, read_concurrency: true])
        refs = %{}
        {:ok, {names, refs}}
    end

    # @impl true
    # def handle_call({:lookup, name}, _from, state) do
    #     {names, _} = state
    #     {:reply, Map.fetch(names, name), state}
    # end

    @impl true
    def handle_call({:create, name}, _from, {names, refs}) do

        case lookup(names, name) do
            {:ok, pid} ->
                {:reply, pid, {names, refs}} 
            :error ->
                {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
                ref = Process.monitor(bucket)
                refs = Map.put(refs, ref, name)
                :ets.insert(names, {name, bucket})
                state = {names, refs}
                {:reply, bucket, state}
        end
        
    end


    @impl true
    def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
        {name, refs} = Map.pop(refs, ref)
        :ets.delete(names, name)
        {:noreply, {names, refs}}
    end

    @impl true
    def handle_info(_msg, state) do
        {:noreply, state}
    end

    
end
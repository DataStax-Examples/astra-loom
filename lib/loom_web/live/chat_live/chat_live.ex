defmodule LoomWeb.ChatLive do
  use Phoenix.LiveView
  alias LoomWeb.Presence

  def mount(_params, session, socket) do
    # grab the user's information from the session
    {:ok, resource, _} = Loom.Guardian.resource_from_token(session["guardian_default_token"])
    # pull the users thread settings
    threads = resource["threads"]
    
    # if we don't have messages, lets load them.
    # Reminder that mount is called twice and we only want to do this once.
    socket = if !Map.has_key?(socket, :messages) do
      socket = assign(socket, messages: [])
      socket = Enum.reduce(threads, socket, fn {name, %{"enabled" => enabled}}, soc ->
        thread_changed({name, enabled}, soc)
      end)
    end
    
    {:ok, assign(socket, 
                  message: "",
                  resource: resource,
                  threads: threads,
                  targets: ["lobby"]
                )}
  end

  # handle a new message sent from another web session
  def handle_info(%{payload: %{message: _} = payload}, socket) do
    {:noreply, assign(socket, messages: sort_messages(socket.assigns[:messages] ++ [payload]))}
  end

  # handle a person actively watching of ignoring a thread
  def handle_info(
    %{event: "presence_diff", payload: %{joins: _joins, leaves: _leaves}},
    socket
  ) do
    {:noreply, socket}
  end

  # handle a submitting a message to a thread
  def handle_event("send", payload, socket) do
    message = %Loom.Message{
      other_threads: Enum.map(socket.assigns.targets, &("t:#{&1}")), # t for topic, more to come
      user: socket.assigns[:resource]["name"],
      message: payload["message"],
      picture: socket.assigns[:resource]["picture"]
    }
    {:ok, saved_messages} = Loom.Message.insert_message(message)
    for thread <- saved_messages.other_threads do
      LoomWeb.Endpoint.broadcast(thread, "shout", message)
    end
    {:noreply, socket}
  end

  # handle message validate as it is typed
  def handle_event("validate", %{"message" => message}, socket) do
    tags = case Regex.scan(~r/#(\w+)/, message) do
      [] ->
        ["lobby"]
      other ->
        Enum.map(other, &List.last(&1))
    end
    {:noreply, assign(socket, targets: tags)}
  end

  # handle a change to a thread (active/de-activated)
  def handle_event("thread", event, socket) do
    threads = socket.assigns[:threads]
    resource = socket.assigns[:resource]
    thread = threads[event["name"]]

    # update messages if needed
    socket = {event["name"], !thread["enabled"] } |>
      thread_changed(socket)
      
    Loom.User.update_thread(resource["sub"], event["name"], !thread["enabled"])
    
    # prep the new threads list to add back to the socket
    threads = Map.put(threads, event["name"], %{"enabled" => !thread["enabled"]})
    {:noreply, assign(socket, threads: threads)}
  end

  defp thread_changed({name, enabled = true}, socket) do
    # other prefixes may be used later, such as 'user:'
    full_name = "t:" <> name
    resource = socket.assigns[:resource]
    LoomWeb.Endpoint.subscribe(full_name)
    presence_info = %{
      online_at: :os.system_time(:milli_seconds),
      uuid: resource["uuid"],
      name: resource["name"],
      picture: resource["picture"]
    }
    Presence.track(
      self(),
      full_name,
      socket.id,
      presence_info
    )
    messages = socket.assigns[:messages] ++ Loom.Message.get_messages(full_name)


    #Loom.Thread.update_thread_by_person(resource, name, true)
    assign(socket, messages: sort_messages(messages))
  end

  defp thread_changed({name, enabled = false}, socket) do
    full_name = "t:" <> name
    Presence.untrack(self(), full_name, socket.id)
    LoomWeb.Endpoint.unsubscribe(full_name)
    messages = Enum.filter(socket.assigns[:messages], &(&1.thread != full_name))

    #Loom.Thread.update_thread_by_person(socket.assigns[:resource]["sub"], thread)
    assign(socket, messages: sort_messages(messages))
  end
  
  defp sort_messages(messages) do
    messages
      |> Enum.sort(&(&1.added < &2.added))
      |> Enum.uniq_by(&(&1.id))
  end
end

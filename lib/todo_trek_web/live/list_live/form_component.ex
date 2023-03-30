defmodule TodoTrekWeb.ListLive.FormComponent do
  use TodoTrekWeb, :live_component

  alias TodoTrek.Todos

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header><%= @title %></.header>
      <.simple_form
        for={@form}
        id="list-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-2">
          <.input field={@form[:title]} type="text" />

          <label>
            <input type="checkbox" name="list[notifications_order][]" />
            prepend
          </label>

          <div id="notifications" phx-hook="SortableInputsFor" class="space-y-2">
            <.inputs_for :let={f_nested} field={@form[:notifications]}>
              <div class="flex space-x-2">
                <input type="hidden" name="list[notifications_order][]" value={f_nested.index} />

                <label>
                  <input type="checkbox" name="list[notifications_delete][]" value={f_nested.index} class="hidden" />
                  <.icon name="hero-x-mark" class="w-6 h-6 relative top-2" />
                </label>
                <.input type="text" field={f_nested[:email]} placeholder="email" />
                <.input type="text" field={f_nested[:name]} placeholder="name" />
              </div>
            </.inputs_for>
          </div>

          <label>
            <input type="checkbox" name="list[notifications_order][]" value="new" />
            Append
          </label>
        </div>

        <:actions>
          <.button phx-disable-with="Saving..." phx-click={hide_modal("list-modal")}>
            Save List
          </.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{list: list} = assigns, socket) do
    changeset = Todos.change_list(list)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"list" => list_params}, socket) do
    changeset =
      socket.assigns.list
      |> Todos.change_list(list_params)
      |> Map.put(:action, :validate)
      |> IO.inspect()

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"list" => list_params}, socket) do
    save_list(socket, socket.assigns.action, list_params)
  end

  defp save_list(socket, :edit_list, list_params) do
    case Todos.update_list(socket.assigns.scope, socket.assigns.list, list_params) do
      {:ok, _list} ->
        {:noreply,
         socket
         |> put_flash(:info, "List updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_list(socket, :new_list, list_params) do
    case Todos.create_list(socket.assigns.scope, list_params) do
      {:ok, _list} ->
        {:noreply,
         socket
         |> put_flash(:info, "List created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    if Ecto.Changeset.get_field(changeset, :notifications) == [] do
      email = %Todos.List.EmailNotification{}
      changeset = Ecto.Changeset.put_change(changeset, :notifications, [email])
      assign(socket, :form, to_form(changeset))
    else
      assign(socket, :form, to_form(changeset))
    end
  end
end
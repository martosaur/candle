defmodule Candle.Game.Answersheet do
  alias Candle.Package

  defstruct players: [],
            topics: %{},
            topics_order: []

  def init(players, %Package{} = package) do
    topics =
      for topic <- package.topics, into: %{} do
        answers =
          for question <- topic.questions, into: %{} do
            answers =
              for player <- players, into: %{} do
                {player.id, nil}
              end

            {question.reward, answers}
          end

        {topic.name, answers}
      end

    players = Enum.map(players, & &1.id)

    %__MODULE__{
      players: players,
      topics: topics,
      topics_order: Enum.map(package.topics, & &1.name)
    }
  end

  def get_score(%__MODULE__{} = sheet, player_id) do
    for topic <- Map.values(sheet.topics) do
      for {reward, %{^player_id => answer}} <- topic do
        case answer do
          true -> reward
          false -> -reward
          _ -> 0
        end
      end
    end
    |> List.flatten()
    |> Enum.sum()
  end

  def add_answer(%__MODULE__{} = sheet, topic_name, question_reward, player_id, result) do
    put_in(sheet.topics[topic_name][question_reward][player_id], result)
  end
end

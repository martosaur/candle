defmodule Candle.Package.Parser do
  @rewards [10, 20, 30, 40, 50]

  def html_to_package(page) do
    {:ok, document} = Floki.parse_document(page)

    %Candle.Package{
      name: "Случайный пакет",
      info: "",
      author: "",
      topics: extract_topics(document)
    }
  end

  def extract_topics(document) do
    document
    |> Floki.find(".random_question")
    |> Enum.map(fn {"div", _, children} ->
      Enum.reject(children, fn
        {"div", _, _} -> true
        _ -> false
      end)
    end)
    |> Enum.map(&parse_raw_topic/1)
  end

  def parse_raw_topic(topic) do
    {topic_name, texts} = extract_questions_texts(topic)
    answers = extract_questions_answers(topic)

    questions =
      for {text, answer, reward} <- Enum.zip([texts, answers, @rewards]) do
        %Candle.Package.Question{
          text: text,
          answer: answer,
          reward: reward
        }
      end

    %Candle.Package.Topic{
      name: topic_name,
      questions: questions
    }
  end

  def extract_questions_texts(topic) do
    [topic_name | questions] =
      topic
      |> Enum.filter(&is_binary/1)
      |> Enum.map(&String.trim/1)
      |> Enum.map(fn s -> String.replace(s, "\n", " ") end)

    {topic_name, questions}
  end

  def extract_questions_answers(topic) do
    topic
    |> Enum.find(fn
      {_, _, children} -> length(children) > 5
      _ -> false
    end)
    |> Floki.children()
    |> Enum.filter(&is_binary/1)
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn s -> String.replace(s, "\n", " ") end)
  end
end

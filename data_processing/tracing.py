import re


def main():
    function_counts = dict()
    trace_count = 0
    with open("output_trace.txt", "r") as file:
        for line in file:
            match = re.match("^(%%% arrayMatrix: )(\\S+)", line)
            if match is not None:
                trace_count += 1
                function_name = match.group(2)
                if function_counts.get(function_name) is not None:
                    function_counts[function_name] += 1
                else:
                    function_counts[function_name] = 1
            match = re.match("", line)
    json_str = (
        "{\n"
        + f"\t\"trace_count\" : {trace_count},\n"
        + "\t\"data\" : {\n"
        + ",\n".join(f'\t\t"{key}": {value}' for key, value in function_counts.items())
        + "\n\t}\n}\n"
    )
    with open("function_counts.json", "w") as file:
        file.write(json_str)


if __name__ == "__main__":
    main()

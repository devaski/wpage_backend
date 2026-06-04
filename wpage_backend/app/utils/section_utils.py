from app.models.page import PageSection


def sort_sections_by_order(sections: list[PageSection]) -> list[PageSection]:
    if all(section.order is None for section in sections):
        return sections

    return [
        section
        for _, section in sorted(
            enumerate(sections),
            key=lambda item: (
                item[1].order if item[1].order is not None else item[0],
                item[0],
            ),
        )
    ]

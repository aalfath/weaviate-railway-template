# Weaviate for Railway: the official image, pinned by version and digest.
# To update: bump the tag and digest below, add a CHANGELOG.md entry, merge to main.
FROM semitechnologies/weaviate:1.40.5@sha256:fe848a3830c8a96fc598c903e39bbaa84a84553e30362663c313643a0febe32a

COPY railway-start.sh /usr/local/bin/railway-start.sh
RUN chmod 0755 /usr/local/bin/railway-start.sh

# 8080: REST/GraphQL API (Railway's $PORT), 50051: gRPC (private network)
EXPOSE 8080 50051
ENTRYPOINT ["/usr/local/bin/railway-start.sh"]
CMD []

# Bicep Enabler TODO

- [ ] Investigate https://github.com/mspnp/AzureNamingTool/tree/main for reusable naming datasets we can extract or sync.
- [ ] Investigate integrating https://raw.githubusercontent.com/mspnp/AzureNamingTool/refs/heads/main/src/repository/resourcetypes.json into our `resourceAbbreviations.bicep` workflow (automation, refresh cadence, conflict resolution).
- [ ] Investigate leveraging https://github.com/Azure/bicep-registry-modules/tree/main for reusable modules and determine how it could plug into the enabler (consumption model, version pinning, contribution workflow).
- [ ] Backfill CAF references for the newly added region abbreviations (stage/geography scopes) and cite the authoritative source in docs.
- [ ] Automate validation that `regionAbbreviations.bicep` stays in sync with `az account list-locations --include-extended-locations`.
- [ ] Revisit stage-region abbreviations once CAF publishes official short codes.
- [ ] Cross-check `resourceAbbreviations.bicep` against the latest Azure Naming Tool dataset and add any missing services.
- [ ] Add CI coverage that exercises `cc . test-enabler -Enabler bicep` after region/resource map updates.

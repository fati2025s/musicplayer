class NamesCollector extends DataCollector {
    @Override
    public Object get(Song music){
        return music.getName();
    }

}